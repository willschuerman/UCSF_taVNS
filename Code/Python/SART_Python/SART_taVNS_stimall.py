
##############################################################################################################
##############################################################################################################
#   Import statements: Do not change
##############################################################################################################
##############################################################################################################
from __future__ import division
from psychopy import visual, core, gui,event, logging, info
from psychopy.visual.ratingscale import RatingScale
import numpy as np
import random
import csv
from datetime import date,datetime
import sys
import platform
import nidaqmx
from nidaqmx import constants
from nidaqmx.stream_writers import AnalogSingleChannelWriter
from scipy import signal

##############################################################################################################
##############################################################################################################
#   EDITABLE PARAMETERS: change editable parameters here
##############################################################################################################
##############################################################################################################

parameters = {
'digitpresentationtime' : 250/1000,
'maskpresentationtime' : 900/1000,
'ITI' : 0,
'responsekey' : 'space',
'responsekey_label' : "space",
'maskheight' : 0.2,
'anticipatoryresponsetime' : 100,
'validresponsetime' : 200,
'run_mindwanderingprobe' : False,
'postprobeduration' : 500
}
trialduration = parameters['digitpresentationtime'] + parameters['maskpresentationtime']

##############################################################################################################
##############################################################################################################
#   EDITABLE STIMULI: change editable stimuli here 
##############################################################################################################
##############################################################################################################

# note: picture of the mask 
mask = 'mask.png'
cognitiveloadsart = "CognitiveLoadSART.mp3"

####################################################################################################
# general instruction expressions: adjust the instruction text depending on device used to run script
####################################################################################################

expressions = {'buttoninstruct1': "",
'buttoninstruct2': "Place your index finger of your dominant hand on the {} button.".format(parameters['responsekey_label'])
}

##############################################################################################################
##############################################################################################################
#   EDITABLE INSTRUCTIONS: change instructions here
##############################################################################################################
##############################################################################################################
instruct = {
    'fontstyle' : ('Arial'),
    'fontsize' : 0.04,
    'txcolor' : 'white'
}
#/fontstyle = ("Arial", 4.00%, false, false, false, false, 5, 1) not sure what the other flags are

#note: These instructions are not original. Please customize.
page = {
    'intro': '''In this task you will be presented with a single digit (1-9)

in varying sizes in the middle of the screen

for a short duration. The digit is followed by a crossed circle.\n

Your task is to\n
 * press the {} when you see any digit other than 3
 
 * don't do anything (press no key) when you see digit 3. Just wait for the next digit.
{}\n

Use the index finger of your dominant hand when responding.\n

It's important to be accurate and fast in this study.\n

Press the SPACEBAR to continue to some practice trials.'''.format(parameters['responsekey_label'],expressions['buttoninstruct1']),

    'practiceend':'''Practice is over and the actual task is about to start. There will be no error feedback anymore.\n

Remember:\n
Whenever there is a digit other than 3 (e.g. 1, 2, 4, 5, 6, 7, 8, 9), press the SPACE key as fast as you can.

However, if digit 3 is presented, don't do anything. Just wait for the next digit.\n

Use the index finger of your dominant hand when responding.\n

It's important to be accurate and fast in this study.\n

the task will take ~4 minutes.\n

Press the SPACEBAR to start.\n'''.format(parameters['responsekey_label'])}

###############################
# General Helper Instructions
##############################

getReady_Params = {'items': 'Get Ready: {}'.format(expressions['buttoninstruct2']),
    'fontstyle':'Arial',
    'size':(0.10,0.06)}

##############################################################################################################
##############################################################################################################
#	EDITABLE LISTS: change editable lists here
##############################################################################################################
##############################################################################################################

fontsizes = [0.1,0.13,0.16,0.19,0.21]
ntrials = 225

##############################################################################################################
##############################################################################################################
#	QUESTIONS
##############################################################################################################
##############################################################################################################
# present a dialogue to change params
expInfo = {
    'group':'0',
    'subject':'test',
    'amplitude':0.1,
    'pulse width':200,
    'debug': 0,
    'nblocks':4
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


params = {}
params.update({"sr":24000.00, "amp":1, "freq":25, "pw":200, 'npulse':15})
params.update({"duration_test":params['npulse']/params["freq"]}) # 15 = npulses, "pw": 15/(params["freq"]*100) <- why?
buf = MakeStimBuffer(params)
fake_buf = np.zeros(len(buf))
##############################################################################################################
##############################################################################################################
#	DEFAULTS
##############################################################################################################
##############################################################################################################
# script requires Inquisit 5.0.5.0 or higher
# Ideally, we will bundle this into a docker thing or something like that 
# can change these to be psychopy/python versions, but hopefully won't be necessary

defaults = {'fontstyle': 'Arial',
    'fontsize' : 0.05,
    'txbgcolor': 'white',
    'txcolor' : (0,0,0),
    'screencolor':(-1,-1,-1) 
}

# initialize clocks and wait times for experiment
globalClock = core.Clock()
trialClock = core.Clock() 
logging.setDefaultClock(globalClock)

maskperiod = core.StaticPeriod()

# might be better to make each column a dictionary
data = {'columns':('build','computer.platform','date','time','subject','group','blockcode','blocknum',
'trialcode','trialnum','expressions.trialcount','parameters.digitpresentationtime',
'parameters.maskpresentationtime','values.trialtype','values.digit','values.fontsize','response','correct',
'values.RT','latency','values.latencytype','values.responsetype','values.count_anticipatory',
'values.correctsuppressions','values.count_NoGo','values.incorrectsuppressions','values.count_Go',
'values.count_validGo','values.dostim','radiobuttons.difficulty.response','radiobuttons.interest.response')
}


lastLog = logging.LogFile("logs\{}_{}_tvns_sart.log".format(subject,group), level=logging.INFO, filemode='w')
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

# global variables that are updated during the experiment
fourfilled = 0
RT1 = 0
RT2 = 0
RT3 = 0
RT4 = 0

correctsuppressions = 0
incorrectsuppressions = 0
count_NoGo = 0
count_Go = 0
count_validGo = 0
count_anticipatory = 0
count_4RTs_successsuppression = 0
count_4RTs_failedsuppression = 0
sumRT_successsuppression = 0
sumRT_failedsuppression = 0

# Note: list created on runtime; it saves all valid latencies of correct Go trials
# in order to calculate Std of correct and valid Go-latencies

validgolatencies = []
trial_data = []
summary_data = []

###################################################################################################################
###################################################################################################################
#	STIMULI
###################################################################################################################
###################################################################################################################

# initialize window
mywin = visual.Window(monitor="testMonitor", units="deg",
    color=defaults['screencolor'],fullscr=True) # this initializes the window as black, which is what I seem to remember. 

getReadyText = visual.TextStim(mywin, text=getReady_Params['items'],
    font=getReady_Params['fontstyle'], # To do: not sure we have the 'Symbol' font, may need to add
    units='norm',
    height = getReady_Params['size'][1], # it might be close enough like this? # ToDo
    color=(1,1,1), # white
    pos=(0,0))

intro_page = visual.TextStim(mywin, text=page['intro'],
    font='Arial', # To do: not sure we have the 'Symbol' font, may need to add
    units='norm',
    height = 0.05, # it might be close enough like this?
    color=(1,1,1), # white
    pos=(0,0))

practiceend_page = visual.TextStim(mywin, text=page['practiceend'],
    font=getReady_Params['fontstyle'], # To do: not sure we have the 'Symbol' font, may need to add
    units='norm',
    height = getReady_Params['size'][1], # it might be close enough like this? # ToDo
    color=(1,1,1), # white
    pos=(0,0))

# initialize text digit <- updated on every trial
digit = visual.TextStim(mywin, text='',
    font=defaults['fontstyle'], # To do: not sure we have the 'Symbol' font, may need to add
    units='height',
    height=defaults['fontsize'], 
    color=(1,1,1))
digit.autoDraw = False  # Automatically draw every frame

# load the mask image
fixation = visual.ImageStim(mywin,image=mask,units='height',size=0.2)
fixation.height = 0.2

errorfeedback = visual.TextStim(mywin, text='Incorrect',
    font=defaults['fontstyle'], # To do: not sure we have the 'Symbol' font, may need to add
    units='height',
    height=0.04, 
    color=(1,-1,-1), # red
    pos=(0,0))
errorfeedback.autoDraw = False  # Automatically draw every frame


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

def feedback():
    errorfeedback.draw()
    mywin.flip()
    core.wait(0.5)
    
    mywin.flip()

###################################################################################################################
###################################################################################################################
# FUNCTIONS
###################################################################################################################
###################################################################################################################

def present_page(page):
    page.draw()
    mywin.flip()
    waitForButtonPress(waitTime=0,waitforpress = True)
    mywin.flip(clearBuffer=True)

def createdata(suffix = ''):
    # open files, write headers, close
    raw_data_log = open('logs/G{}S{}_sart_log{}.csv'.format(group,subject,suffix),'w',newline='',encoding='utf-8')
    raw_data_writer = csv.writer(raw_data_log)
    raw_data_writer.writerow(data['columns'])

    return raw_data_writer, raw_data_log

def record_data(raw_data_writer,trial_data): # add all the variables that change on each trial. 
    # record raw data
    raw_data_writer.writerow(trial_data)
    # raw_data_log.open('w')
    # raw_data_log.writerow(trial_data)
    # raw_data_log.close()

#############################
# General Helper Trial
#############################

#This trial is used when participants are asked to place their fingers on specific response
#buttons. On the touchscreen, this trial presents the (inactive) response buttons to the participants.
def getReady():
    trialduration = 5
    getReadyText.draw()
    mywin.flip()
    #core.wait(trialduration)
    waitForButtonPress()
    
    mywin.flip(clearBuffer=True)

###################################################################################################################
###################################################################################################################
#	PRACTICE TRIALS
###################################################################################################################
###################################################################################################################


def practice_trial(digitvalue,fontsize):
    pretrialpause = parameters['ITI'] # get ITI for this trial
    
    # Update digit presentation text
    digit.height = fontsize
    digit.text = digitvalue

    if digitvalue==3:
        trialtype='practice_nogo'
    else:
        trialtype='practice_go'

    # Set up fixation
    fixation.draw()

    # wait for the inter-trial-interval
    core.wait(pretrialpause)

    # Start recording button presses
    event.clearEvents()
    trialClock.reset()
            
    # Show fixation
    mywin.flip()
    maskperiod.start(parameters['maskpresentationtime'])  # start a period of 0.5s
    # Draw digit while mask is displayed 
    digit.draw()
    maskperiod.complete() 
    # show digit
    mywin.flip()
    core.wait(parameters['digitpresentationtime'])
    keys = event.getKeys(keyList=["q","space"],timeStamped=trialClock) # get just the first time space was pressed
    print('keys are {}'.format(keys))
    if len(keys) > 0:
        keys = keys[0]
        response = keys[0]
        latency = round((keys[1])*1000) # convert to ms
    else:
        response = "0"
        latency = 0

    # check for quit key
    if response =='q':
        core.quit()
    # record overall time
    trialduration = trialClock.getTime()

    # revert to black screen
    mywin.flip(clearBuffer=True)

    if response == parameters['responsekey']:
        RT = latency
    else:
        RT = 0
        latencytype = 0

    if RT != 0 and RT < parameters['anticipatoryresponsetime']:
        latencytype=1
    elif RT != 0 and RT >= parameters['anticipatoryresponsetime'] and RT < parameters['validresponsetime']:
        latencytype=2
    elif RT != 0 and RT >= parameters['validresponsetime']:
        latencytype=3 

    if trialtype == 'practice_go':
        if RT == 0:
            responsetype = "Omission"
        elif RT != 0 and RT < parameters['anticipatoryresponsetime']:
            responsetype = "Go Anticipatory"
        elif RT >= parameters['anticipatoryresponsetime'] and RT < parameters['validresponsetime']:
            responsetype = "Go Ambiguous";
        elif RT >= parameters['validresponsetime']:
            responsetype = "Go Success"
    elif trialtype == 'practice_nogo':
        if RT == 0:
            responsetype = "NoGo Success"
        else:
            responsetype = "NoGo Failure"

    # determine accuracy and feedback (if practice)
    if responsetype == "NoGo Success" or responsetype == "Go Success":
        correct = 1
    else:
        correct = 0

    if correct==0: # I invented where this should be set
        feedback()
    
    print('latency was {}, latencytype was {}, RT was {}\n'.format(latency,latencytype,RT))
    print('responsetype was {}\n'.format(responsetype))

    return response, latency, trialduration, RT, latencytype, responsetype, correct, trialtype

###################################################################################################################
###################################################################################################################
#	TRIALS
###################################################################################################################
###################################################################################################################

def trial(digitvalue,fontsize,dostim):
    pretrialpause = parameters['ITI'] # get ITI for this trial
    
    # define globals
    global count_Go
    global count_NoGo
    global incorrectsuppressions
    global count_anticipatory
    global count_validGo
    global validgolatencies
    global fourfilled
    global correctsuppressions
    global count_4RTs_successsuppression
    global count_4RTs_failedsuppression
    global sumRT_failedsuppression
    global sumRT_successsuppression
    global RT1
    global RT2
    global RT3
    global RT4
    global fourfilled

    if digitvalue==3:
        trialtype='nogo'
    else:
        trialtype='go'

    # update values
    if trialtype=='go':
        count_Go += 1

    elif trialtype=='nogo':
        count_NoGo += 1

    # Update digit presentation text
    digit.height = fontsize
    digit.text = digitvalue

    # Set up fixation
    fixation.draw()

    # wait for the inter-trial-interval
    core.wait(pretrialpause)

    # Start recording button presses
    event.clearEvents()
    trialClock.reset()
            
    # Show fixation
    mywin.logOnFlip(level=logging.EXP, msg='mask start')
    mywin.flip()
    maskperiod.start(parameters['maskpresentationtime'])  # start a period of 0.5s

    # STIMULATE HERE
    if dostim:
        logging.log(level=logging.EXP, msg='stim start')
        task.start()
        
    # Draw digit while mask is displayed 
    digit.draw()
    maskperiod.complete() 
    # show digit
    mywin.logOnFlip(level=logging.EXP, msg='digit start')
    mywin.flip()
    core.wait(parameters['digitpresentationtime'])
    keys = event.getKeys(keyList=["q","space"],timeStamped=trialClock) # get just the first time space was pressed

    if len(keys) > 0:
        keys = keys[0]
        response = keys[0]
        latency = round((keys[1])*1000) # convert to ms

        # check for quit key
        if response =='q':
                # CALL SAFE STOP TO STIMULATION
            if dostim:
                task.wait_until_done(10)
                task.stop()
                logging.log(level=logging.EXP, msg='stim stop')
            raw_data_log.close()
            mywin.close()
            core.quit()
    else:
        response = "0"
        latency = 0

    # record overall time
    trialduration = trialClock.getTime()

    # revert to black screen
    mywin.logOnFlip(level=logging.EXP, msg='digit cleared')
    mywin.flip(clearBuffer=True)

    # CALL SAFE STOP TO STIMULATION
    if dostim:
        task.wait_until_done(10)
        task.stop()
        logging.log(level=logging.EXP, msg='stim stop')

    # define RT for valid response
    if response == parameters['responsekey']:
        RT = latency
    else:
        RT = 0
        latencytype = 0

    # define latency type for valid response
    if RT != 0 and RT < parameters['anticipatoryresponsetime']:
        latencytype=1
    elif RT != 0 and RT >= parameters['anticipatoryresponsetime'] and RT < parameters['validresponsetime']:
        latencytype=2
    elif RT != 0 and RT >= parameters['validresponsetime']:
        latencytype=3

    # define response type 
    if trialtype == 'go':
        if RT == 0:
            responsetype = "Omission"
            incorrectsuppressions += 1
        elif RT != 0 and RT < parameters['anticipatoryresponsetime']:
            responsetype = "Go Anticipatory"
            count_anticipatory += 1
        elif RT >= parameters['anticipatoryresponsetime'] and RT < parameters['validresponsetime']:
            responsetype = "Go Ambiguous";
        elif RT >= parameters['validresponsetime']:
            responsetype = "Go Success"
            count_validGo += 1
            validgolatencies.append(RT)
            
        if RT != 0 and responsetype=="Go Success":
            RT1 = RT2
            RT2 = RT3
            RT3 = RT4
            RT4 = RT
        else:
            RT1 = 0
            RT2 = 0
            RT3 = 0
            RT4 = 0
            fourfilled=0
        
        if responsetype=="Go Success" and RT1 != 0 and RT2 != 0 and RT3 != 0 and RT4 != 0:
            fourfilled = 1

    elif trialtype == 'nogo':
        if RT == 0:
            responsetype = "NoGo Success"
            correctsuppressions += 1
        else:
            responsetype = "NoGo Failure"
        
        if RT == 0 and fourfilled == 1:
            count_4RTs_successsuppression +=1
            sumRT_successsuppression += (RT1 + RT2 + RT3 + RT4)
        elif RT != 0 and fourfilled == 1:
            count_4RTs_failedsuppression +=1
            sumRT_failedsuppression += (RT1 + RT2 + RT3 + RT4)
        
        RT1 = 0
        RT2 = 0
        RT3 = 0
        RT4 = 0
        fourfilled = 0

    # determine accuracy and feedback (if practice)
    if responsetype == "NoGo Success" or responsetype == "Go Success":
        correct = 1
    else:
        correct = 0

    # write to log
    logging.flush()
    # return
    return trialtype, response, latency, trialduration, RT, latencytype, responsetype, correct

###################################################################################################################
###################################################################################################################
#	BLOCKS
###################################################################################################################
###################################################################################################################
def block_practice():

    blockcode = 'practice'
    blocknum = 0

    # show instructions to participant
    preinstructions = (intro_page)
    preinstructions.draw()
    mywin.flip()
    waitForButtonPress()

    raw_data_writer, raw_data_log = createdata('_tvns_practice')
    getReady()
    
    # generate practice_digitsequence
    practice_digitsequence = np.repeat(np.arange(1,10),2)
    
    # randomize
    random.shuffle(practice_digitsequence)
    random.shuffle(fontsizes)

    # initialize counters
    digit_counter = 0
    fontsize_counter=0
    for trx in range(len(practice_digitsequence)):

        digitvalue = practice_digitsequence[digit_counter]
        fontsize = fontsizes[fontsize_counter]

        response, latency, trialduration, RT, latencytype, responsetype, correct, trialtype = practice_trial(digitvalue,fontsize)
        
        # apply appropriate formatting to variables
        trialcode = trialtype.lower()
        fontsize = '{}ptc'.format(fontsize)*100
        
        # record data
        trial_data = [build, computer, current_date,current_time,subject,group,blockcode,blocknum,trialcode,trx+1,trx+1,
            int(parameters['digitpresentationtime']*100), int(parameters['maskpresentationtime']*100), trialtype, digitvalue, fontsize,
            response, correct, RT, latency, latencytype, responsetype, count_anticipatory,correctsuppressions, count_NoGo, 
            incorrectsuppressions, count_Go, count_validGo, 
            0,0,0] #
            # build,computer.platform,date,time,subject,group,blockcode,blocknum,trialcode,trialnum    expressions.trialcount,
            # parameters.digitpresentationtime,parameters.maskpresentationtime,values.trialtype    values.digit,values.fontsize,
            # response,correct,values.RT,latency,values.latencytype,values.responsetype,values.count_anticipatory,values.correctsuppressions,values.count_NoGo,
            # values.incorrectsuppressions,values.count_Go,values.count_validGo,
            # values.countprobes,radiobuttons.difficulty.response,radiobuttons.interest.response

        record_data(raw_data_writer,trial_data)

        # update trial values
        digit_counter += 1
        fontsize_counter +=1 
        if fontsize_counter==len(fontsizes):
            random.shuffle(fontsizes)
            fontsize_counter=0

    # close practice log
    raw_data_log.close()

    # do the post instruction page
    postinstructions = practiceend_page
    postinstructions.draw()
    mywin.flip()
    waitForButtonPress()


def block_SART(trialcount,b):
    blockcode = 'SART'
    blocknum = b+1

    getReady()

    # set up trials for block
    ndigits = len(np.arange(1,10))
    nreps = int(ntrials/ndigits)
    expr_digitsequence = np.repeat(np.arange(1,10),nreps)

    # randomize
    random.shuffle(expr_digitsequence) # fully randomized
    random.shuffle(fontsizes)

    # set up stimulation sequence
    expr_stimsequence = np.zeros(len(expr_digitsequence))
    nogo_idxs = np.where(expr_digitsequence==3)[0]
    for nogotrial in range(len(nogo_idxs)):
        idx = nogo_idxs[nogotrial]
        low_idx = idx-2
        high_idx = idx+2
        if low_idx <0:
            low_idx = 0
        if high_idx>len(expr_stimsequence):
            high_idx = len(expr_stimsequence)

        expr_stimsequence[idx-2:idx+3] = 1
        

    # initialize counters
    digit_counter = 0
    fontsize_counter=0
    for trx in range(len(expr_digitsequence)):

        digitvalue = expr_digitsequence[digit_counter]
        fontsize = fontsizes[fontsize_counter]
        if debug:
            dostim = 0
        else:
            dostim = expr_stimsequence[digit_counter]
            
        trialtype, response, latency, trialduration, RT, latencytype, responsetype, correct = trial(digitvalue,fontsize,dostim)
        
        # apply appropriate formatting to variables
        trialcode = trialtype.lower()
        fontsize = '{}ptc'.format(int(round(fontsize*100)))
        
        # record data
        trialnum = trx+1
        trial_data = [build, computer, current_date,current_time,subject,group,blockcode,blocknum,trialcode,trialnum,trialcount,
            int(parameters['digitpresentationtime']*100), int(parameters['maskpresentationtime']*100), trialtype, digitvalue, fontsize,
            response, correct, RT, latency, latencytype, responsetype, count_anticipatory,correctsuppressions, count_NoGo, 
            incorrectsuppressions, count_Go, count_validGo, 
            dostim,0,0] #
        record_data(raw_data_writer,trial_data)

        # update trial values
        trialcount +=1
        digit_counter += 1
        fontsize_counter +=1 
        if fontsize_counter==len(fontsizes):
            random.shuffle(fontsizes)
            fontsize_counter=0

    return trialcount

###################################################################################################################
###################################################################################################################
#	EXPERIMENT
###################################################################################################################
###################################################################################################################
def expt():
    global subject
    global group
    global computer
    global raw_data_log
    global raw_data_writer

    # get debug or not
    global debug
    debug = bool(expInfo['debug'])

    # get computer info
    computer = platform.system()


    if debug:
        # run practice block
        block_practice()

        # run experiment blocks
        raw_data_writer,raw_data_log = createdata('_tvns_expr')
        trialcount = 1
        for b in range(int(float(expInfo['nblocks']))):
            trialcount = block_SART(trialcount,b)

        raw_data_log.close()        
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

            # write the actual waveform to the buffer
            writer.write_many_sample(buf)

            # run practice block
            block_practice()

            # run experiment blocks
            raw_data_writer,raw_data_log = createdata('_tvns_expr')
            trialcount = 1
            for b in range(int(float(expInfo['nblocks']))):
                trialcount = block_SART(trialcount,b)

            raw_data_log.close()

        completed = 1


expt() # run the experiment
mywin.close() # end experiment
core.quit()

##############################################################################################################
#												End of File
##############################################################################################################
