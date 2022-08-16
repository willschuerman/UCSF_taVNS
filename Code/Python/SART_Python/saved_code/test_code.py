from __future__ import division

from psychopy import visual, core, gui,event, logging,info
from psychopy.hardware import keyboard
from psychopy.visual.ratingscale import RatingScale
import random
import matplotlib.pyplot as plt
import nidaqmx
from scipy import signal
import numpy as np



#system = nidaqmx.system.System.local()
#system.driver_version

# for device in system.devices:
#     print(device)

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
params.update({"sr":24000.00, "amp":1, "freq":25, "pw":200, 'npulse':2})
params.update({"duration_test":params['npulse']/params["freq"]}) # 15 = npulses, "pw": 15/(params["freq"]*100) <- why?
buf = MakeStimBuffer(params)
t = np.linspace(0,params['duration_test'],len(buf))

fig, ax1 = plt.subplots()

ax1.set_ylabel("amplitude")
ax1.set_xlabel("time")
ax1.plot(t, buf, "black")
fig.set_dpi(100)
plt.show()
core.wait(1) # need this otherwise zoom doesn't work
plt.close()

# parameters = {
# 'digitpresentationtime' : 250,
# 'maskpresentationtime' : 900,
# 'ITI' : 0,
# 'responsekey' : 57,
# 'responsekey_label' : "SPACEBAR",
# 'maskheight' : 0.2,
# 'anticipatoryresponsetime' : 100,
# 'validresponsetime' : 200,
# 'run_mindwanderingprobe' : False,
# 'postprobeduration' : 500
# }
# expressions = {'buttoninstruct1': "The Spacebar response button will be located at the bottom of your screen.",
# 'buttoninstruct2': "Place your index finger of your dominant hand over the {} button.".format(parameters['responsekey_label'])
# }
# page = {
#     'intro': '''In this task you will be presented with a single digit (1-9) in varying sizes in the middle of the screen
# for a short duration. The digit is followed by a crossed circle.\n

# Your task is to\n
#  * press the {} when you see any digit other than 3\n
#  * don't do anything (press no key) when you see digit 3. Just wait for the next digit.\n
# {}\n

# Use the index finger of your dominant hand when responding.\n

# It's important to be accurate and fast in this study.\n

# Press the SPACEBAR to continue to some practice trials.'''.format(parameters['responsekey_label'],expressions['buttoninstruct1']),

#     'practiceend':'''Practice is over and the actual task is about to start. There will be no error feedback anymore.\n

# Remember:\n
# Whenever there is a digit other than 3 (e.g. 1, 2, 4, 5, 6, 7, 8, 9), press the {}\n
# as fast as you can. However, if digit 3 is presented, don't do anything. Just wait for the next digit.\n

# Use the index finger of your dominant hand when responding.\n

# It's important to be accurate and fast in this study.\n

# the task will take ~4 minutes.\n

# Press the SPACEBAR to start.\n'''.format(parameters['responsekey_label'])}


# # '''Performance OBS: in general, TextStim is slower than many other visual stimuli, 
# # i.e. it takes longer to change some attributes. In general, it’s the attributes that 
# # affect the shapes of the letters: text, height, font, bold etc. These make the next 
# # .draw() slower because that sets the text again. You can make the draw() quick by 
# # calling re-setting the text (myTextStim.text = myTextStim.text) when you’ve 
# # changed the parameters.'''


# # set up response function
# def getResponse(waitTime=0,waitforpress = False):
#     # get response
#     event.clearEvents()
#     clock = core.Clock()

#     if waitforpress == True:
#         keys = event.waitKeys(keyList=["q","space"],timeStamped=clock)
#     else:
#         if waitTime ==0:
#             keys = event.getKeys(keyList=["q","space"],timeStamped=clock)[0] # if not explicitly waiting
#         else:
#             keys = event.waitKeys(keyList=["q","space"],timeStamped=clock,maxWait=waitTime)
    
#     if keys is None: # if there was no response
#         response = ""
#         latency = 0
#     else:
#         response = keys[0] # get name (should be space)
#         latency = keys[1] # get latency
#         if response =='q':
#             core.quit()
#     return response, latency

#getResponse(waitforpress=True)

# mywin = visual.Window(monitor="testMonitor", units="deg",color=(-1,-1,-1),fullscr=True) # this initializes the window as black, which is what I seem to remember. 

# practiceend_page = visual.TextStim(mywin, text=page['practiceend'],
#     font='Arial', # To do: not sure we have the 'Symbol' font, may need to add
#     units='norm',
#     height = 0.04, 
#     color=(1,1,1),# white
#     pos=(0,0))

# practiceend_page.draw()
# mywin.flip()
# event.clearEvents()
# clock = core.Clock()
# ISI = core.StaticPeriod()
# ISI.start(5)
# ISI.complete()
# keys = event.getKeys(keyList=["q","space"],timeStamped=clock) # get just the first space pressed
# print(keys)
# response = keys[0]
# latency = keys[1]

# #response, latency = getResponse(3)
# print('response was {}, latency was {}'.format(response,latency))


# mywin.close()
# core.quit()

# probe_caption = visual.TextStim(mywin,pos=(0,0.1), text="Please click on the option below which best describes your experience with the task just now.",
#     font='Arial',units='height',height=0.03)
# probe_caption.autoDraw = False

# probe_choices = ["I was thinking \n about the task", 
# "My mind was blank",
# "My mind drifted \n to things other \n than the task, \n but I wasn’t \n aware of it \n until you asked me", 
# "While doing the task \n I was aware that \n thoughts about other things\n popped into my head"]
# probe = RatingScale(mywin,scale=None,  textFont='Arial',textSize=0.6,choices=probe_choices,
#     markerStart=0.5, singleClick=True,stretch=2.5,pos=(0,-0.2),marker='hover',mouseOnly=True,showAccept=False)
# while probe.noResponse:
#     probe_caption.draw()
#     probe.draw()
#     mywin.flip()
# radioresponse = probe.getRating()
# probe_response = probe_choices.index(radioresponse)+1 # don't index at zero
# #print('You chose {}: {}'.format(probe_response,radioresponse))

# continue_prompt = visual.TextStim(mywin,pos=(0,0.1), text="Please move your hand back to the keyboard.\n\nPress the <Spacebar> to continue with the task.",
#     font='Arial',units='height',height=0.04)
# probe_caption.autoDraw = False


# difficulty_caption = visual.TextStim(mywin,pos=(0,0.1), text="How difficult was the task?",
#     font='Arial',units='height',height=0.03)
# difficulty_caption.autoDraw = False
# difficulty_choices = ["Very easy",  "Moderately easy", "Neither easy nor difficult", "Moderately difficult",
# "Very difficult"]
# difficulty = RatingScale(mywin,scale=None,  textFont='Arial',textSize=0.6, choices=difficulty_choices,
#     markerStart=0.5, singleClick=True,stretch=2.5,pos=(0,-0.2),marker='hover',mouseOnly=True,showAccept=False)
# while difficulty.noResponse:
#     difficulty_caption.draw()
#     difficulty.draw()
#     mywin.flip()
# radioresponse = difficulty.getRating()
# difficulty_response = difficulty_choices.index(radioresponse)+1 # don't index at zero

# interest_caption = visual.TextStim(mywin,pos=(0,0.1), text="How interesting was the task?",
#     font='Arial',units='height',height=0.03)
# interest_caption.autoDraw = False
# interest_choices = ["Not at all interesting", "A little interesting", "Somewhat interesting",  "Pretty interesting",
# "Highly Interesting"]
# interest = RatingScale(mywin,scale=None,  textFont='Arial',textSize=0.6, choices=interest_choices,
#     markerStart=0.5, singleClick=True,stretch=2.5,pos=(0,-0.2),marker='hover',mouseOnly=True,showAccept=False)
# while interest.noResponse:
#     interest_caption.draw()
#     interest.draw()
#     mywin.flip()
# radioresponse = interest.getRating()
# interest_response = interest_choices.index(radioresponse)+1 # don't index at zero
# #print('You chose {}: {}'.format(interest_response,radioresponse))


# sysinfo = info.RunTimeInfo(mywin)
# mywin.close()
# print(sysinfo.keys())
# core.quit()

# expInfo = {
#     'Participant ID':''
# }

# # present a dialogue to change params
# dlg = gui.DlgFromDict(expInfo, title='simple JND Exp', fixed=['dateStr'])
# if dlg.OK:
#     print('Participant # {}'.format(expInfo['Participant ID']))
#     #toFile('lastParams.pickle', expInfo)  # save params to file for next time
# else:
#     core.quit()  # the user hit cancel so exit

# # set up experiment log (why this instead of the other one?)
# logging.console.setLevel(logging.WARNING)
# # overwrite (filemode='w') a detailed log of the last run in this dir
# lastLog = logging.LogFile("lastRun.log", level=logging.INFO, filemode='w')
# # also append warnings to a central log file
# centralLog = logging.LogFile("logs/logfile.log", level=logging.WARNING, filemode='a')

# logging.log(level=logging.WARN, msg='something important')
# logging.log(level=logging.EXP, msg='something about the conditions')
# logging.log(level=logging.DATA, msg='something about a response')
# logging.log(level=logging.INFO, msg='something less important')

# # make a text file to save data
# # fileName = expInfo['Participant ID']# + expInfo['dateStr']
# # dataFile = open(fileName+'.csv', 'w')  # a simple text file with 'comma-separated-values'
# # dataFile.write('targetSide,oriIncrement,correct\n') # headers

# # initialize window
# mywin = visual.Window(monitor="testMonitor", units="deg",
#     color=[-1,-1,-1],fullscr=True)

# # initialize clock for experiment
# globalClock = core.Clock()
# trialClock = core.Clock()
# logging.setDefaultClock(globalClock)

# # load the fixation image
# fixation = visual.ImageStim(mywin,image='mask.png',units='height',size=0.2)
# fixation.height = 0.2
# # fixation.draw()
# # mywin.flip()
# # core.wait(1)

# # initialize message
# message = visual.TextStim(mywin, text='',font='Arial',units='height',height=0.05)
# message.autoDraw = False  # Automatically draw every frame

# str_repo = ['fuck','crap','oh damn','no', 'stop','wait','oh no','no really','oh god','please']




# # set up keyboard (interesting, why do you need this? maybe different hardware setups? )
# kb = keyboard.Keyboard()
# # during your trial
# kb.clock.reset()  # when you want to start the timer from
# keys = kb.getKeys(['right', 'left', 'quit'], waitRelease=True)
# if 'quit' in keys:
#     core.quit()
# for key in keys:
#     print(key.name, key.rt, key.duration)

# # set up response function
# def getResponse():
#     # get response
#     kb.clock.reset()  # when you want to start the timer from
#     keys = kb.getKeys(waitRelease=False,clear=True)
#     if 'q' in keys:
#         core.quit()
#     for key in keys:
#         print(key.name, key.rt, key.duration)

# #draw the stimuli and update the window
# while True: #this creates a never-ending loop
#     # message.text = str(random.randint(1,10))  # Change properties of existing stim
#     # core.wait(0.2)
#     # mywin.flip()
#     fixation.draw()
#     mywin.flip()
#     core.wait(0.2)

#     the_text = str_repo[random.randrange(0,len(str_repo))]
#     message.text = the_text
#     message.text = message.text # don't know if this helps, but the docs say to do this if you are changing fonts
#     message.draw()
#     mywin.flip()
#     getResponse()

#     #mywin.clearBuffer(color=True)
#     # write data to file
#     #dataFile.write('%i,%.3f,%i\n' %(the_text))
#     # dataFile.write('%s\n' %(the_text))
#     # if len(event.getKeys())>0:
#     #     break
#     # event.clearEvents()

# #cleanup
# mywin.close()
# core.quit()