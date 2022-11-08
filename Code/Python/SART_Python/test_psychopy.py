

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

digitperiod = core.StaticPeriod()
maskperiod = core.StaticPeriod()

# might be better to make each column a dictionary
data = {'columns':('build','computer.platform','date','time','subject','group','blockcode','blocknum',
'trialcode','trialnum','expressions.trialcount','parameters.digitpresentationtime',
'parameters.maskpresentationtime','values.trialtype','values.digit','values.fontsize','response','correct',
'values.RT','latency','values.latencytype','values.responsetype','values.count_anticipatory',
'values.correctsuppressions','values.count_NoGo','values.incorrectsuppressions','values.count_Go',
'values.count_validGo','values.dostim','values.amp','values.order')
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

###

### run test
pretrialpause = parameters['ITI']
for tr in range(20):
    # wait for the inter-trial-interval
    core.wait(pretrialpause)

    # set up digit
    digit.draw()

    # Set keyboard presses to none
    key_pressed = False

    # Start recording button presses <- Trial Timer Start
    event.clearEvents()
    trialClock.reset()

    # show digit <- Digit Presentation
    mywin.logOnFlip(level=logging.EXP, msg='digit start')
    while trialClock().getTime() <= parameters['digitpresentationtime']:
        mywin.flip()
        if key_pressed == False:
            keys = event.getKeys(keyList=["q","space"],waitRelease=False,timeStamped=trialClock) # get just the first time space was pressed

        #digitperiod.start(parameters['digitpresentationtime'])  # start a period of 0.25s

    # Set up Fixation Mask
    fixation.draw()

    mywin.logOnFlip(level=logging.EXP, msg='mask start')
    while trialClock().getTime() <= parameters['maskpresentationtime']:
        mywin.flip()
        if key_pressed == False:
            keys = event.getKeys(keyList=["q","space"],waitRelease=False,timeStamped=trialClock) # get just the first time space was pressed

    print(keys)
    if len(keys) > 0:
        keys = keys[0]
        response = keys[0]
        latency = round((keys[1])*1000) # convert to ms
    else:
        response = "0"
        latency = 0