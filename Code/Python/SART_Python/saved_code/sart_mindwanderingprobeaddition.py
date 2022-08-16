# <usermanual>
						
# 									SART MIND WANDERING PROBE ADDITION 
# 								# helper script (does not run on its own)#
# SCRIPT INFO

# Script Author: Katja Borchert, Ph.D. (katjab@millisecond.com) for Millisecond Software, LLC
# last updated:  04-18-2016 by K.Borchert for Millisecond Software LLC

# Copyright ©  04-18-2016 Millisecond Software


# BACKGROUND INFO

# 											#Purpose#
# The "Mindwandering Probe" addition presents a surveypage that probes whether participant's attention is wandering 
# after 4% of randomly selected SART trials throughout the task as well as a post SART survey with
# 2 radiobutton questions that inquire about perceived difficulty and interest of the SART task.

# # If the default number of SART trials in SART.iqx (225) is changed, go to section Editable Lists 
# and change list.mindwanderingprobes accordingly.
# # By default, the probes are called randomly. To control the sequence of probes, go go
# go to section Editable Lists and follow further instructions.

# The Mindwandering Probe addition is modelled after:
# Jackson, J.D. & Balota, D.A. (2012). Mind-wandering in Younger and Older Adults: Converging
# Evidence from the Sustained Attention to Response Task and Reading for Comprehension.
# Psychol Aging, 27(1): 106–119 (Exp.2).


# </usermanual>

# ##############################################################################################################
# ##############################################################################################################
# 	EDITABLE LISTS: change editable lists here
# ##############################################################################################################
# ##############################################################################################################

# Note: 
# 0 = no probe trial should be run after SART trial
# 1 = probe trial should be run after SART trial

# This list controls the random sampling of probe trials during the SART.
# It selects randomly without replacement a 0 (in 96% of 225 trials = 216) and a 1 (in 4% of 225 trials = 9).

# !If the number of trials is changed from 225, change the item list accordingly. 

# !The probes can also be 
# # tied to list.digitsequence by replacing replace = false with /selectionmode = list.digitsequence.currentindex
# # called in sequence by replacing /replace = false with /selectionmode = sequence
# The position of the probes in the sequence can be edited below.

mindwanderingprobes = {
    'items':[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 
0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
    'replace':False,
    'currentindex':0
}

##############################################################################################################
#						!!!REMAINING CODE: Customize after careful consideration only!!!
##############################################################################################################
from psychopy import visual
from psychopy.visual.ratingscale import RatingScale


##############################################################################################################
##############################################################################################################
#	QUESTIONS
##############################################################################################################
##############################################################################################################

mywin = visual.Window(monitor="testMonitor", units="deg",color=(-1,-1,-1),fullscr=True) # this initializes the window as black, which is what I seem to remember. 

probe_caption = visual.TextStim(mywin,pos=(0,0.1), text="Please double click on the option below which best describes your experience with the task just now.",
    font='Arial',units='height',height=0.03)
probe_caption.autoDraw = False

probe_choices = ["I was thinking \n about the task", 
"My mind was blank",
"My mind drifted \n to things other \n than the task, \n but I wasn’t \n aware of it \n until you asked me", 
"While doing the task \n I was aware that \n thoughts about other things\n popped into my head"]
probe = RatingScale(mywin,scale=None,  textFont='Arial',textSize=0.6,choices=probe_choices,
    markerStart=0.5, singleClick=True,stretch=2.5,pos=(0,-0.2),marker='hover',mouseOnly=True,showAccept=False)
while probe.noResponse:
    probe_caption.draw()
    probe.draw()
    mywin.flip()
radioresponse = probe.getRating()
probe_response = probe_choices.index(radioresponse)+1 # don't index at zero
#print('You chose {}: {}'.format(probe_response,radioresponse))

continue_prompt = visual.TextStim(mywin,pos=(0,0.1), text="Please move your hand back to the keyboard.\n\nPress the <Spacebar> to continue with the task.",
    font='Arial',units='height',height=0.04)
probe_caption.autoDraw = False

difficulty_caption = visual.TextStim(mywin,pos=(0,0.1), text="How difficult was the task?",
    font='Arial',units='height',height=0.03)
difficulty_caption.autoDraw = False
difficulty_choices = ["Very easy",  "Moderately easy", "Neither easy nor difficult", "Moderately difficult",
"Very difficult"]
difficulty = RatingScale(mywin,scale=None,  textFont='Arial',textSize=0.6, choices=difficulty_choices,
    markerStart=0.5, singleClick=True,stretch=2.5,pos=(0,-0.2),marker='hover',mouseOnly=True,showAccept=False)
while difficulty.noResponse:
    difficulty_caption.draw()
    difficulty.draw()
    mywin.flip()
radioresponse = difficulty.getRating()
difficulty_response = difficulty_choices.index(radioresponse)+1 # don't index at zero

interest_caption = visual.TextStim(mywin,pos=(0,0.1), text="How interesting was the task?",
    font='Arial',units='height',height=0.03)
interest_caption.autoDraw = False
interest_choices = ["Not at all interesting", "A little interesting", "Somewhat interesting",  "Pretty interesting",
"Highly Interesting"]
interest = RatingScale(mywin,scale=None,  textFont='Arial',textSize=0.6, choices=interest_choices,
    markerStart=0.5, singleClick=True,stretch=2.5,pos=(0,-0.2),marker='hover',mouseOnly=True,showAccept=False)
while interest.noResponse:
    interest_caption.draw()
    interest.draw()
    mywin.flip()
radioresponse = interest.getRating()
interest_response = interest_choices.index(radioresponse)+1 # don't index at zero
#print('You chose {}: {}'.format(interest_response,radioresponse))


##############################################################################################################
##############################################################################################################
#	SURVEYPAGES	
##############################################################################################################
##############################################################################################################

# Note: to be presented at random times during the SART 
# <surveypage probe>
# /questions = [1 = probe]
# / fontstyle = ("Arial", 3%, false, false, false, false, 5, 1)
# / txcolor = black
# /itemfontstyle = ("Arial", 2.5%, false, false, false, false, 5, 1)
# /responsefontstyle = ("Arial", 2%, false, false, false, false, 5, 1)
# /showbackbutton = false
# /showpagenumbers = false
# /showquestionnumbers = false
# /ontrialbegin = [values.trialtype = "probe"; values.digit = ""; values.RT = ""; values.latencytype = ""; values.responsetype = ""]
# /branch = [trial.SARTprepare]
# </surveypage>

# <trial SARTprepare>
# /stimulusframes = [1 = background, continue]
# /validresponse = (57)
# /recorddata = false
# / posttrialpause = parameters.postprobeduration
# </trial>

# Note: to be presented at the end of the task
# <surveypage posttasksurvey>
# /questions = [1 = difficulty, interest]
# / fontstyle = ("Arial", 3%, false, false, false, false, 5, 1)
# / txcolor = black
# /itemfontstyle = ("Arial", 2.5%, false, false, false, false, 5, 1)
# /responsefontstyle = ("Arial", 2%, false, false, false, false, 5, 1)
# /showbackbutton = false
# /showpagenumbers = false
# /showquestionnumbers = false
# /itemspacing = 20%
# </surveypage>

##############################################################################################################
##############################################################################################################
#	BLOCKS
##############################################################################################################
##############################################################################################################

# <survey posttasksurvey>
# /skip = [parameters.run_mindwanderingprobe == false]
# /pages = [1 = posttasksurvey]
# </survey>

##############################################################################################################
#												End of File
##############################################################################################################