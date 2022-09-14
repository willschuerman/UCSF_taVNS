# This script initiates a staircase procedure, and returns a data file containing the staircase report
# 
			
                
##############################################################################################################
##############################################################################################################
#   Import statements: Do not change
##############################################################################################################
##############################################################################################################
from __future__ import division
from psychopy import visual, core, gui,event, logging, info
from psychopy.visual.ratingscale import RatingScale
import numpy as np
import csv
from datetime import date,datetime
import sys
import platform
import nidaqmx
from nidaqmx import constants
from nidaqmx.stream_writers import AnalogSingleChannelWriter
from scipy import signal
import time
import matplotlib.pyplot as plt

##############################################################################################################
##############################################################################################################
#  Intro GUI
##############################################################################################################
##############################################################################################################

# present a dialogue to change params
expInfo = {
    'group':'0',
    'subject':'test',
    'amplitude':0.1,
    'pulse width':200,
    'debug':False
}

dlg = gui.DlgFromDict(expInfo, title='SART Task', fixed=['dateStr'])
if dlg.OK:
    print('Participant # {}'.format(expInfo['subject']))
    #toFile('lastParams.pickle', expInfo)  # save params to file for next time
else:
    core.quit()  # the user hit cancel so exit
subject = expInfo['subject']
group = expInfo['group']

    
##############################################################################################################
##############################################################################################################
#   EDITABLE INSTRUCTIONS: change instructions here
##############################################################################################################
##############################################################################################################
instruct = {
    'fontstyle' : ('Arial'),
    'fontsize' : 0.04,
    'txcolor' : 'black'
}
#/fontstyle = ("Arial", 4.00%, false, false, false, false, 5, 1) not sure what the other flags are

#note: These instructions are not original. Please customize.
page = {'intro': '''You will receive brief bursts of tVNS. \n 
    This can feel like a sudden warming, tingling, or tapping sensation. \n
    When prompted, press 2 if you felt the tVNS, and 1 if you did not. \n
    Only press 2 if you are certain that you felt something. If unsure, press 1.\n\n
    Press space to begin.'''}

##############################################################################################################
##############################################################################################################
#	EDITABLE LISTS: change editable lists here
##############################################################################################################
##############################################################################################################

# Note: 
# pre-fixed, semi-randomly assembled sequence of trialtypes/225 digits (9 digits # 25 repetitions)
# => Robertson et al (1997) distributed digit 3 in a prefixed semi-randomly fashion across the 225 trials.
# To create a randomly selected sequence of digits that is created while running the experiment as
# opposed to a pre-fixed one: replace /selectionmode = sequence with /replace = false


##############################################################################################################
##############################################################################################################
#	tVNS Setup
##############################################################################################################
##############################################################################################################

system = nidaqmx.system.System.local()
system.driver_version

for device in system.devices:
    print(device)

def biphasic_waveform(amp, pw, ipd=0, sr=24414.0625):

    pws = np.floor(pw*sr/1e6) 
    ipds = np.floor(ipd*sr/1e6)

    wf = np.zeros(int(pws*2+ipds))
    wf[:int(pws)] = -amp
    wf[len(wf)-int(pws):] = amp
    wf = np.append(wf,0) # ensure that last sample is zero
    return wf


def constant_rate_pulser(f, dur, sr=24414.0625):

    ipis = np.floor(sr/f)
    durs = np.floor(dur*sr)

    pt = np.zeros(int(durs))
    for i in range(0, int(durs-ipis),int(ipis)):
        pt[i] = 1

    return pt


def MakeStimBuffer(params):
    #print params
    # %% generate the biphasic waveform
    wf = biphasic_waveform(params["amp"], params["pw"],ipd=50)
    #print wf
    # %% generate the train for the test block
    # % create the 30Hz train
    ptTest = constant_rate_pulser(params["freq"], params["duration_test"])
    #plt.plot(ptTest)
    yTest = signal.convolve(ptTest, wf)
    ypad = np.zeros(100)
    yTest = np.concatenate((ypad, yTest),axis=0)
    # %% generate the buffer
    # buf = np.zeros((params["nchan"],len(yTest)))
    # buf[1,:] = np.tile(yTest,[1,1])

    return yTest


##############################################################################################################
##############################################################################################################
#	DEFAULTS
##############################################################################################################
##############################################################################################################
# script requires Inquisit 5.0.5.0 or higher
# Ideally, we will bundle this into a docker thing or something like that 
# can change these to be psychopy/python versions, but hopefully won't be necessary

defaults = {'fontstyle': 'Arial',
    'fontsize' : 0.04,
    'txbgcolor': 'white',
    'txcolor' : (0,0,0),
    'screencolor':(-1,-1,-1) # We don't need the rectangle background
    }

# initialize clocks and wait times for experiment
globalClock = core.Clock()
trialClock = core.Clock() 
logging.setDefaultClock(globalClock)
maskperiod = core.StaticPeriod()


# might be better to make each column a dictionary
data = {'columns':('build','computer.platform','date','time','subject','group',
    'trial','amplitude','pulsewidth','response','runningmean')
}

##############################################################################################################
##############################################################################################################
#	VALUES: automatically updated
##############################################################################################################
##############################################################################################################

# need to make sure all these values exist, only the constant ones (e.g., subject) are global

# get date and time
monthday = '{d.month}{d.day}'.format(d = date.today())
year = '{d.year}'.format(d = date.today())
current_date = monthday + year[2:4]
current_time = '{d.hour}:{d.minute}:{d.second}'.format(d = datetime.now())

build = '{}'.format(sys.version[0:6])


###################################################################################################################
###################################################################################################################
#	STIMULI
###################################################################################################################
###################################################################################################################

# initialize window
mywin = visual.Window(monitor="testMonitor", units="deg",
    color=defaults['screencolor'],fullscr=True) # this initializes the window as black, which is what I seem to remember. 

intro_page = visual.TextStim(mywin, text=page['intro'],
    font='Arial', # To do: not sure we have the 'Symbol' font, may need to add
    units='norm',
    height = 0.04, # it might be close enough like this?
    color=(1,1,1), # white
    pos=(0,0))

# initialize text digit <- updated on every trial
fixation = visual.TextStim(mywin, text='+',
    font=defaults['fontstyle'], # To do: not sure we have the 'Symbol' font, may need to add
    units='height',
    height=defaults['fontsize'], 
    color=(1,1,1))
fixation.autoDraw = False  # Automatically draw every frame

# initialize text digit <- updated on every trial
responsePrompt = visual.TextStim(mywin, text="1 = I didn't feel it.\t 2 = I felt it.",
    font=defaults['fontstyle'], # To do: not sure we have the 'Symbol' font, may need to add
    units='height',
    height=defaults['fontsize'], 
    color=(1,1,1))
responsePrompt.autoDraw = False  # Automatically draw every frame

###################################################################################################################
###################################################################################################################
#	RESPONSES
###################################################################################################################
###################################################################################################################

# set up response function
def waitForButtonPress(waitTime=0):
    # get response
    event.clearEvents()
    clock = core.Clock()

    if waitTime ==0:
        keys = event.waitKeys(keyList=["q","space"],timeStamped=clock)[0] # if not explicitly waiting
    else:
        keys = event.waitKeys(keyList=["q","space"],timeStamped=clock,maxWait=waitTime)
    if keys is not None:
        response = keys[0] # get name (should be space)
        if response =='q':
            core.quit()

###################################################################################################################
###################################################################################################################
# FUNCTIONS
###################################################################################################################
###################################################################################################################

def present_page(page):
    page.draw()
    mywin.flip()
    waitForButtonPress(waitTime=0)
    mywin.flip(clearBuffer=True)
    

def createdata():
    # open files, write headers, close
    raw_data_log = open('logs/G{}S{}_staircaseTVNS.csv'.format(group,subject),'w',newline='')
    raw_data_writer = csv.writer(raw_data_log)
    raw_data_writer.writerow(data['columns'])

    return raw_data_log, raw_data_writer

def record_data(raw_data_writer,trial_data): # add all the variables that change on each trial. 
    # record raw data
    raw_data_writer.writerow(trial_data)
    # raw_data_log.open('w')
    # raw_data_log.writerow(trial_data)
    # raw_data_log.close()

###################################################################################################################
###################################################################################################################
#	TRIALS
###################################################################################################################
###################################################################################################################

# Note: 
# presents digit for parameters.digitpresentationtime followed by a mask for parameters.maskpresentationtime
# latency is measured from onset of digit 
# summary variables are updated
# latencies are tracked to be able to calculate the mean latencies of the last 4 consecutive non-digit3 trials 
# that elicited a correct response before a digit3 trial
# latencies of Go-success trials are stored in validgolatencies to calculate Std

def trial(params, nreversals, buf):
    # update buffer
    writer.write_many_sample(buf)
    
    # Set up fixation
    fixation.draw()
    core.wait(0.5) # wait for 500ms between trials

    # clear button preses
    event.clearEvents()
    trialClock.reset()

    # Show fixation
    mywin.flip()
    core.wait(0.1) # wait for 100ms

    # Stimulate
    start_time = time.time()
    task.start()
    core.wait(0.601) # just in case
    task.wait_until_done(10)
    task.stop()
    print("--- %s seconds ---" % (time.time() - start_time))
    # Draw digit while mask is displayed 
    responsePrompt.draw()
    mywin.flip()

    # Start recording button presses
    keys = event.waitKeys(keyList=["q","1","2"],timeStamped=trialClock)
    response = keys[0][0]

    # revert to black screen
    mywin.flip(clearBuffer=True)

    # check for quit key
    if response =='q':
        raw_data_log.close()
        mywin.close()
        core.quit()
    elif response == '1':
        if nreversals==0:
            params['amp'] = params['amp']+0.2
        else:
            params['amp'] = params['amp']+0.1
    elif response == '2':
        nreversals+=1
        params['amp'] = params['amp']-0.3

    params['amp'] = np.round(params['amp'],2)
    

    return params, nreversals, response

def debug_trial(params, nreversals, buf):
    # update buffer
    #writer.write_many_sample(buf)
    
    # Set up fixation
    fixation.draw()
    core.wait(0.5) # wait for 500ms between trials

    # clear button preses
    event.clearEvents()
    trialClock.reset()

    # Show fixation
    mywin.flip()
    core.wait(0.1) # wait for 100ms

    # Stimulate
    start_time = time.time()
    #task.start()
    core.wait(0.601) # just in case
    #task.wait_until_done(10)
    #task.stop()
    print("--- %s seconds ---" % (time.time() - start_time))
    # Draw digit while mask is displayed 
    responsePrompt.draw()
    mywin.flip()

    # Start recording button presses
    keys = event.waitKeys(keyList=["q","1","2"],timeStamped=trialClock)
    response = keys[0][0]

    # revert to black screen
    mywin.flip(clearBuffer=True)

    # check for quit key
    if response =='q':
        raw_data_log.close()
        mywin.close()
        core.quit()
    elif response == '1':
        if nreversals==0:
            params['amp'] = params['amp']+0.2
        else:
            params['amp'] = params['amp']+0.1
    elif response == '2':
        nreversals+=1
        params['amp'] = params['amp']-0.3

    params['amp'] = np.round(params['amp'],2)
    

    return params, nreversals, response

def expr(expInfo):
    global defaults

    debug = expInfo['debug'] # change to True to run without stimulation
    # set tVNS params
    params = {}
    params.update({"sr":24000.00, "amp":expInfo['amplitude'], "freq":25, "pw":expInfo['pulse width'], 'npulse':50})
    params.update({"duration_test":params['npulse']/params["freq"]}) 
    buf = MakeStimBuffer(params)
    fake_buf = np.zeros(len(buf))

    # get computer info
    computer = platform.system()

    # show instructions to participant
    preinstructions = (intro_page)
    preinstructions.draw()
    mywin.flip()
    waitForButtonPress()
    global raw_data_log

    if bool(debug):
        blockcode = 'staircase_debug'
        raw_data_log, raw_data_writer = createdata()
        nreversals = 0

        trialn = 0
        ampvec = []
        plotvec = []

        while (nreversals < 8) and (params['amp'] > 0) and (params['amp']<3):
            trialn+=1
            plotvec.append(params['amp'])

            #buf = MakeStimBuffer(params)
            params, nreversals, response = debug_trial(params, nreversals,buf)
            print(params['amp'])
            if nreversals == 1:
                ampvec.append(params['amp'])
                runningmean = 0
            elif nreversals > 2:
                ampvec.append(params['amp'])
                runningmean = np.mean(ampvec)
            else:
                runningmean = 0
            
            trial_data = [build, computer, current_date, current_time, subject, group,trialn, params['amp'],params['pw'],response,runningmean]
            record_data(raw_data_writer,trial_data)
            #print(trial_data)
            #print(ampvec)

            # update buf
            if params['amp']>3:
                params['amp']=3

            elif params['amp']<0.1:
                params['amp']=0.0

    else:
            
        global task
        global writer
        with nidaqmx.Task() as task:
            task.ao_channels.add_ao_voltage_chan("Dev1/ao1") # check output channel on DAQ
            task.timing.cfg_samp_clk_timing(rate=params["sr"],
                                    sample_mode=constants.AcquisitionType.FINITE,  # FINITE or CONTINUOUS
                                    samps_per_chan=len(buf))
            writer = AnalogSingleChannelWriter(task.out_stream,auto_start=False)

            # run first buffer as zeros (hack)
            writer.write_many_sample(fake_buf)
            task.start()
            core.wait(0.601) # just in case
            task.wait_until_done(10)
            task.stop()
            
            
            blockcode = 'staircase'
            #global raw_data_log
            raw_data_log, raw_data_writer = createdata()
            nreversals = 0

            trialn = 0
            ampvec = []
            plotvec = []

            while (nreversals < 8) and (params['amp'] > 0) and (params['amp']<3):
                trialn+=1
                plotvec.append(params['amp'])

                buf = MakeStimBuffer(params)
                params, nreversals, response = trial(params, nreversals,buf)
                print(params['amp'])
                if nreversals == 1:
                    ampvec.append(params['amp'])
                    runningmean = 0
                elif nreversals > 2:
                    ampvec.append(params['amp'])
                    runningmean = np.mean(ampvec)
                else:
                    runningmean = 0

                trial_data = [build, computer, current_date, current_time, subject, group,trialn, params['amp'],params['pw'],response,runningmean]
                record_data(raw_data_writer,trial_data)
                #print(trial_data)
                #print(ampvec)

                # update buf
                if params['amp']>3:
                    params['amp']=3

                elif params['amp']<0.1:
                    params['amp']=0.0
                    
            task.close()
            
    raw_data_log.close()                    
    print('Threshold = {}, stim level = {}'.format(np.round(runningmean,2),np.round(runningmean,2)-0.2))

    mywin.close()
    
    # plot staircase (this doesn't seem to work, psychopy problem)
    plt.plot(np.arange(1,len(plotvec)+1),plotvec)
    plt.hlines(y=runningmean,xmin=1,xmax=len(plotvec)+1)
    plt.show()

    # on staircase end
    core.quit()


# Run Staircase
expr(expInfo)


##############################################################################################################
#												End of File
##############################################################################################################
