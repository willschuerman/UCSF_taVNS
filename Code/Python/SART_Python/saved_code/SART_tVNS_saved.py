# '''
# SUSTAINED ATTENTION TO RESPONSE TASK (SART)
# 								   (with optional "Mindwandering Probes")
# SCRIPT INFO

# Inquisit Script Author: Katja Borchert, Ph.D. (katjab@millisecond.com) for Millisecond Software, LLC
# Date: 10-15-2013
# last updated: 02-13-2017 by K.Borchert (katjab@millisecond.com) for Millisecond Software LLC
# converted to python: 05-16-2022 by William L. Schuerman (William.Schuerman@ucsf.edu) for University of California San Francisco
# Copyright © 02-13-2017 Millisecond Software


# BACKGROUND INFO

# 											#Purpose#
# This script implements the Sustained Attention to Response Task (SART) as described in:

# Robertson, I. H., Manly, T., Andrade, J., Baddeley, B. T., & Yiend, J. (1997). ‘Oops!’: Performance correlates of 
# everyday attentional failures in traumatic brain injured and normal subjects. Neuropsychologia, 35(6), 747–758.

# and 

# Cheyne, J.A., Solman, G.J.F., Carriere, J.S.A., & Smilek, D. (2009). Anatomy of an error: A bidirectional state model of task
# engagement/disengagement and attention-related errors. Cognition, 111, 98–113.

# The SART is a type of Go/NoGo task in which the nogo stimulus is presented very infrequently.

# Note: This script includes an optional "Mindwandering Probe" addition for the SART.py.
# The code is provided in helper script "SART_MindWanderingProbeAddition.py". More info about
# the mindwandering probe in the additional script.
# To run the probe addition, go to section Editable Parameters and set parameters['run_mindwanderingprobe'] = True (default is False)


# 											  #Task#
# Participants are presented with a single digit 1-9 in the middle of the screen in varying expr_fontsizes.
# The digit disappears after a short while and is replaced with a mask (circle with an X).
# Participants are asked to press the SPACEBAR if any digit other than 3 is presented and to withhold the response
# if digit 3 presented.


# DATA FILE INFORMATION: 
# The default data stored in the data files are:

# (1) Raw log file: 'SART.txt' (a separate file for each participant)

# version:						Python version
# distribution:                   Psychopy distribution
# computer.platform:				the platform the script was run on
# date, time, subject, group:		date and time script was run with the current subject/groupnumber 

# (2) Raw data file: 'SART.csv' (a separate file for each participant)
# date, time, subject, group:		date and time script was run with the current subject/groupnumber 
# blockcode, blocknum:			the name and number of the current block
# trialcode, trialnum: 			the name and number of the currently recorded trial
# 									(Note: not all trials that are run might record data; by default data is collected unless /record_data = false is set for a particular trial/block) 
# trialcount:					    counts all test trials
# digitpresentationtime:			digit duration in ms (default: 250ms)
# maskpresentationtime:			mask duration in ms (default: 900ms)

# trialtype:						"Go" (digit !=3); "NoGo" (digit == 3)
# digit:							contains the currently selected digit
# fontsize:						contains the currently (randomly) selected fontsize
# response:						the participant's response
# 										SART trials: 0 for no response or 57 for Spacebar
# 										Probe trials (if run): the selected anchor digit
# correct:						the correctness of the response (1 = correct; 0 = error)
# RT:								the latency of the response in ms (= trial latency unless no response was given; no response leaves values.RT empty)
# latency: 						the trial latency in ms (if no response, trial latency shows the trialduration)
# latencytype:					0 = no response given (suppression); 1 = anticipatory latency (< parameters['anticipatoryresponsetime']);
# 								2 = ambiguous latency; 3 = valid latency  (>= parameters['validresponsetime)
# 									Note: independent of Go-NoGo trialtype
# responsetype:					"NoGo Success": correctly suppressed response to NoGo trial (digit 3)
# 								"Omission": incorrectly suppressed response to a Go trial (digit other than 3)
# 								"NoGo Failure": any response to a NoGo trial
# 								"Go Anticipatory": anticipatory response for Go trials with latencies < parameters['anticipatoryresponsetime']
# 								"Go Ambiguous": ambiguous response for Go trials
# 								"Go Success": valid response for Go trials with latencies >= parameters['validresponsetime']
# count_anticipatory:			    counts the number of times a Go-latency was faster than parameters['anticipatoryresponsetime']
# correctsuppressions:			counts number of correct suppressions (-> no response to digit 3)
# incorrectsuppressions:			counts number of incorrect suppressions (-> no response to digit other than 3)
# count_NoGo:					    counts NoGo trials (digit 3)
# count_Go:						counts Go trials (digits other than 3)
# count_validGo:					counts Go trials with a correct response and latencies >= parameters['validresponsetime']
# countprobes:					counts the number of probes run

# radiobuttons.difficulty.response:
# radiobuttons.interest.response:			responses to the posttask survey questions

# (3) Summary data file: 'summary.csv' (a separate file for each participant)

# script.startdate:						date script was run
# script.starttime:						time script was started
# script.subjectid:						subject id number
# script.groupid:							group id number
# script.elapsedtime:						time it took to run script (in ms)
# computer.platform:						the platform the script was run on
# completed:								0 = script was not completed (prematurely aborted); 1 = script was completed (all conditions run)
# radiobuttons.difficulty.response:
# radiobuttons.interest.response:			responses to the posttask survey questions (if run)

# dropdown.age.response:					response to the age question at the end of the task
# ageGroup:								the assigned age group (1-6) based on age response. (used for reporting z-scores and percentiles)
# 											!Note: age groups correspond to the age cohorts used by Carriere et al (2010), table 2, p. 572

# nr_commissions:						    absolute number of commission errors in NoGo trials (=NoGo failures; also reported as SART errors)				
# percent_commissions:					percentage of commission errors in NoGo trials (=NoGo failures; also reported as SART errors)
# z_commissions:							z-value of number of Commission errors based on Carriere et al (2010), table 2 (SART errors), p. 572
# percentile_commissions:				percentile of Commission z-value based on Carriere et al (2010), table 2 (SART errors), p. 572
# nr_omissions:							absolute number of omission errors in Go trials (=omission of response)
# percent_omissions:						percentage of incorrect suppressions in Go trials (=omission of response)
# z_omissions:							z-value of number Omission errors based on Carriere et al (2010), table 2, p. 572
# percentile_omissions:					percentile of Omission z-value based on Carriere et al (2010), table 2, p. 572
# count_anticipatory:					    counts the number of times a Go-latency was faster than parameters['anticipatoryresponsetime']
# z_AnticipatoryResponses:				z-value of number Anticipatory Responses based on Carriere et al (2010), table 2, p. 572
# percentile_AnticipatoryResponses:		percentile of Anticipatory Responses z-value based on Carriere et al (2010), table 2, p. 572
# meanRT_go:								mean latency (in ms) of valid and correct Go trials (latencies >= parameters['validresponsetime'])
# stdRT_go:								estimated standard deviation (STD) of valid and correct Go trials
# z_goRT:								    z-value of mean go latency based on Carriere et al (2010), table 2, p. 572
# percentile_goRT:						percentile of goRT z-value based on Carriere et al (2010), table 2, p. 572
# CV_go:									coefficient of variablity (CV = STD/Mean) => a measure of variability independent of mean differences
# z_CV:									z-value of CV based on Carriere et al (2010), table 2, p. 572
# percentile_CV:							percentile of CV z-value based on Carriere et al (2010), table 2, p. 572

# Mean RTs are calculated for the correct consecutive (not interrupted either by a NoGo or by an omission trial) last four Go- trials (digit other than 3) preceding successful NoGo trial
# Mean RTs are calculated for the correct consecutive (not interrupted either by a NoGo or by an omission trial) last four Go- trials (digit other than 3)  preceding preceding failed NoGo trial
# !!!!Note: in this script any 4 correct Go trials are counted irrespective of values['latencytype']

# /meanRT_GObeforesuccessNOGO:			mean latency (in ms) of consecutive 4 correct trials before correct suppression of response to digit 3
# 											(=> a measure of speed before successful NoGo trials)
# /meanRT_GObeforefailedNOGO:				mean latency (in ms) of consecutive 4 correct trials before incorrect response of response to digit 3
# 											(=> a measure of speed before failed NoGo trials)
                                            
# NORMS:
# z-value and percentile calculations use data published by:

# 	Carriere, J.S.A., Cheyne, J.A., Solman, G.J.F. & Smilek, D. (2010). 
# 	Age Trends for Failures of Sustained Attention. Psychology and Aging, 25, 569–574.
    
# Carriere et al (2010) grouped data by 6 age groups (no separate data for gender norms provided)	
# Check helper script SART_Norms.iqx for more details.


# EXPERIMENTAL SET-UP:
# #9 digits, each of them presented 25 times = 225 trials
# #in 5 expr_fontsizes, each of them randomly selected 45 times (distribution across digits is randomly determined)
# #in this script the digit order is semi-random, predetermined 
# no special constraints were used to determine the order (only constraint: each digit is presented 25 times)
# # List properties can be edited to change the order from a pre-fixed one to a random one. Further instructions under
# (see section Editable Lists -> list.expr_digitsequence for more information)

# Trial Sequence:
# digit (250ms) -> mask (900ms) -> <digit SOA: 1150ms> -> digit.....

# => Response latencies are measured from onset of digit and can therefore catch anticipatory responses 
# 	(latencies faster than parameters['anticipatoryresponsetime']) (see discussion in Cheyne et al, 2009)

# STIMULI
# - digits 1-9 presented in fontstyle "Symbol" (if available on computer) 
# - in 5 expr_fontsizes
# 	=> expr_fontsizes in this script are based on screen percentages and can be customized under 
# 	section Editable Lists -> list.expr_fontsizes
# - a picture mask (circle with an X) section Editable Stimuli -> picture.mask
# - stimuli/mask presented in white on a black background

# INSTRUCTIONS
# Instructions are not original and can be customized under section Editable Instructions

# EDITABLE CODE:
# check below for (relatively) easily editable parameters, stimuli, instructions etc. 
# Keep in mind that you can use this script as a template and therefore always "mess" with the entire code to further customize your experiment.

# The parameters you can change are:

# /digitpresentationtime:			digit duration in ms (default: 250ms)
# /maskpresentationtime:			mask duration in ms (default: 900ms)
# /ITI:							intertrial interval in ms (default: 0 => digit SOA is therefore 1150ms)
# /responsekey:					the scancode of the response key (here: 57 -> Spacebar)
# 									Note: find scancodes under Tools -> Keyboard Scancodes	
# /responsekey_label:				Label of response key (here: SPACEBAR)		
# /maskheight:					the height/size of the mask (default: 20%)
# 									Note: Robertson et al (1997): mask size on their screen ~29mm
# /anticipatoryresponsetime:		by default, latencies (in ms) are measured from digit onset
# 								latencies faster than anticipatoryresponsetime are interpreted as anticipatory
# 								as opposed to ambiguous/true responses to the digit (default: 100ms)
# 								(-> Cheyne et al, 2009)
# /validresponsetime:				latencies (in ms) that are at or above validresponsetime are considered true 
# 								responses to the digits (default: 200ms)
# 								(-> Cheyne et al, 2009)

# Minderwandering Probe Addition:
# /run_mindwanderingprobe:		true: script runs the mindwandering probe addition
# 								false: script does not run the mindwandering probe addition  (default)
# /postprobeduration:				intertrial pause between probe and re-start of SART (in ms)

# </usermanual>

# '''						
                
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
is_touch_screen = False # change this to True if using a touch screen

if is_touch_screen:
    expressions = {'buttoninstruct1': "The Spacebar response button will be located at the bottom of your screen.",
    'buttoninstruct2': "Place your index finger of your dominant hand over the {} button.".format(parameters['responsekey_label'])
    }
else:
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
    'fontsize' : 0.07,
    'txcolor' : 'black'
}
#/fontstyle = ("Arial", 4.00%, false, false, false, false, 5, 1) not sure what the other flags are

#note: These instructions are not original. Please customize.
page = {
    'intro': '''In this task you will be presented with a single digit (1-9) in varying sizes in the middle of the screen
for a short duration. The digit is followed by a crossed circle.\n

Your task is to\n
 * press the {} when you see any digit other than 3\n
 * don't do anything (press no key) when you see digit 3. Just wait for the next digit.\n
{}\n

Use the index finger of your dominant hand when responding.\n

It's important to be accurate and fast in this study.\n

Press the SPACEBAR to continue to some practice trials.'''.format(parameters['responsekey_label'],expressions['buttoninstruct1']),

    'practiceend':'''Practice is over and the actual task is about to start. There will be no error feedback anymore.\n

Remember:\n
Whenever there is a digit other than 3 (e.g. 1, 2, 4, 5, 6, 7, 8, 9), press the {}\n
as fast as you can. However, if digit 3 is presented, don't do anything. Just wait for the next digit.\n

Use the index finger of your dominant hand when responding.\n

It's important to be accurate and fast in this study.\n

the task will take ~4 minutes.\n

Press the SPACEBAR to start.\n'''.format(parameters['responsekey_label'])}

###############################
# General Helper Instructions
##############################

getReady_Params = {'items': 'Get Ready: {}'.format(expressions['buttoninstruct2']),
    'fontstyle':'Arial',
    'size':(0.08,0.04)}

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

expr_trialtype = {'items':['go','go','go','go','go','go','go','go','go','go','go','go','go','nogo','go','go','go','go','go','go','go','go','go','go','go',
'go','go','go','go','go','go','go','go','go','go','go','nogo','go','go','go','nogo','go','go','go','go','go','go','go','go','go',
'nogo','go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','nogo','go','go','go','go','nogo','go','go',
'go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','nogo','nogo','go','go','go','go','go',
'go','go','go','go','nogo','go','go','go','go','go','nogo','go','go','go','go','nogo','go','go','go','go','go','go','go','nogo','go',
'go','go','go','go','go','go','go','go','go','go','go','go','nogo','go','go','go','go','go','go','go','nogo','go','go','go','go',
'go','go','go','go','go','go','nogo','go','nogo','go','go','nogo','go','go','go','go','go','go','go','go','go','nogo','go','go','go',
'go','nogo','go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','go','nogo','go','go','go',
'nogo','go','nogo','go','go','go','go','go','go','go','go','go','go','go','go','nogo','nogo','go','go','go','go','nogo','go','go','go'],
'selectionmode':'sequence', # don't shuffle
'resetinterval': 1, # how many blocks are run before shuffling occurs 
'currentindex' : 0} 

expr_stimtype = {'items':['nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','stim','stim','stim','stim','stim','stim','stim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim',
'nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','nostim','nostim','nostim','stim','stim','stim',
'stim','stim','stim','stim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim',
'stim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','stim','stim','stim','stim','stim','stim','stim','stim','nostim','nostim',
'nostim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','nostim','stim','stim','stim','stim','stim',
'stim','stim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','stim','stim','stim','stim','stim','stim','stim','nostim','stim','stim','stim','stim','stim','stim','stim','nostim',
'nostim','nostim','nostim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','nostim','nostim','nostim','stim','stim','stim','stim','stim','stim','stim',
'stim','stim','stim','stim','stim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','nostim','stim','stim','stim','stim','stim','stim','stim',
'stim','stim','stim','stim','stim','stim','nostim','nostim','nostim','nostim','nostim','nostim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim','stim'],
'selectionmode':'sequence', # don't shuffle
'resetinterval': 1, # how many blocks are run before shuffling occurs 
'currentindex' : 0} 


expr_digitsequence = {'items':[1,4,1,1,5,1,8,6,5,7,7,9,2,3,8,5,5,6,1,8,9,8,2,7,6,
4,8,6,8,2,9,8,9,5,2,4,3,5,5,6,3,2,7,5,7,8,2,7,4,1,
3,7,4,6,4,8,8,4,1,9,9,4,8,2,2,8,7,3,4,7,1,4,3,5,9,
8,4,7,4,1,2,6,6,4,6,6,9,9,7,6,4,1,7,3,3,9,8,2,7,6,
6,1,9,9,3,1,4,1,1,2,3,6,8,5,9,3,9,5,5,4,2,6,8,3,8,
4,4,2,5,2,1,1,5,9,5,4,5,3,4,2,5,6,9,4,6,3,1,5,5,4,
6,4,5,5,6,2,3,8,3,1,9,3,2,7,6,6,2,2,8,8,6,3,2,1,6,
1,3,1,7,2,9,9,8,7,2,7,9,7,1,4,8,5,9,5,6,9,3,9,8,7,
3,4,3,1,6,5,9,2,7,7,1,8,7,1,7,3,3,2,2,7,5,3,7,8,9],
#'selectionmode' : trialtype['currentindex'], <- not needed
'resetinterval' : 1,
'currentindex':0} # How many blocks to do before re-randomization
expr_digitsequence['items'] = [str(x) for x in expr_digitsequence['items']] # pre-convert to string format

# Note: list of practice trialtypes
practice_trialtype = {
    'items':['practice_go', 'practice_go', 'practice_nogo', 'practice_go', 'practice_go', 'practice_go', 'practice_go', 'practice_go', 'practice_go',
'practice_go', 'practice_go', 'practice_nogo', 'practice_go', 'practice_go', 'practice_go', 'practice_go', 'practice_go', 'practice_go'],
    'selectionmode':'sequence',
    'replace': False,
    'currentindex':0
}

# Note: list of digits used for practice; tied to list.practice_trialtypes
practice_digitsequence = {
    'items':[1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    #'selectionmode': practice_trialtype['currentindex']
    'currentindex':0
}
practice_digitsequence['items'] = [str(x) for x in practice_digitsequence['items']] # pre-convert to string format

# list of random expr_fontsizes in % of canvas height (for psychopy, use proportion). Customize % to fit your screen.
# => Robertson et al (1997): sizes on their screen ranged from 12mm-29mm
# Fontsizes are randomly selected without replacement => same frequency
# across all 225 trials

expr_fontsizes = {
    'items': [0.1,0.13,0.16,0.19,0.21],
    'poolsize': 225,
    'replace' : False, 
    'resetinterval' : 1,
    'currentindex':0
}
practice_fontsizes = {
    'items': [0.1,0.13,0.16,0.19,0.21],
    'replace' : True,
    'currentindex':0
}

 #### from Mindwandering ####
# Note: 
# 0 = no probe trial should be run after SART trial
# 1 = probe trial should be run after SART trial

# This list controls the random sampling of probe trials during the SART.
# It selects randomly without replacement a 0 (in 96% of 225 trials = 216) and a 1 (in 4% of 225 trials = 9).

# !If the number of trials is changed from 225, change the item list accordingly. 

# !The probes can also be 
# # tied to list.expr_digitsequence by replacing replace = false with /selectionmode = list.expr_digitsequence.currentindex
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
##############################################################################################################
#	QUESTIONS
##############################################################################################################
##############################################################################################################
# present a dialogue to change params
expInfo = {
    'group':'0',
    'subject':'test',
    'amplitude':0.1,
    'pulse width':200
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
#				!!!REMAINING CODE: Customize after careful consideration only!!!
##############################################################################################################


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


##############################################################################################################
##############################################################################################################
#	DEFAULTS
##############################################################################################################
##############################################################################################################
# script requires Inquisit 5.0.5.0 or higher
# Ideally, we will bundle this into a docker thing or something like that 
# can change these to be psychopy/python versions, but hopefully won't be necessary

defaults = {'minimumversion':"5.0.5.0",
    'fontstyle': 'Arial',
    'fontsize' : 0.03,
    'txbgcolor': 'white',
    'txcolor' : (0,0,0),
    'screencolor':(-1,-1,-1) # We don't need the rectangle background
    }

# initialize clocks and wait times for experiment
globalClock = core.Clock()
trialClock = core.Clock() 
logging.setDefaultClock(globalClock)

waitperiod = core.StaticPeriod()

##############################################################################################################
##############################################################################################################
#	INCLUDE
##############################################################################################################
##############################################################################################################

# ToDo: Change these to import statements (and fix the corresponding files)
# <include>
# / file = "SART_MindWanderingProbeAddition.iqx"
# / file = "SART_Norms.iqx"
# </include>

##############################################################################################################
##############################################################################################################
#	DATA
##############################################################################################################
##############################################################################################################

# Note: data file explanations under User Manual Information at the top


####################
# data log
####################
# To Do: Figure out how I want to store this
#log = '{},{},{},{},{},{}'.format(build, computer_platform, date, time, subject, group)

####################
# raw data - Note that there are separate files created for the practice and the test blocks (both summary and raw)
####################

# might be better to make each column a dictionary
data = {'columns':('build','computer.platform','date','time','subject','group','blockcode','blocknum',
'trialcode','trialnum','expressions.trialcount','parameters.digitpresentationtime',
'parameters.maskpresentationtime','values.trialtype','values.digit','values.fontsize','response','correct',
'values.RT','latency','values.latencytype','values.responsetype','values.count_anticipatory',
'values.correctsuppressions','values.count_NoGo','values.incorrectsuppressions','values.count_Go',
'values.count_validGo','values.countprobes','radiobuttons.difficulty.response','radiobuttons.interest.response'),
'separatefiles':True
}
# /columns = (date, time, subject, group, blockcode, blocknum, trialcode, trialnum, expressions.trialcount,
# parameters.digitpresentationtime, parameters.maskpresentationtime, values.trialtype, values.digit, values.fontsize, 
# response, correct, values.RT, latency, values.latencytype, values.responsetype, values.count_anticipatory,
# values.correctsuppressions, values.count_NoGo, values.incorrectsuppressions, values.count_Go, values.count_validGo, values.countprobes,
# radiobuttons.difficulty.response, radiobuttons.interest.response)
# /separatefiles = true
# </data>

####################
# summary data
####################

summarydata = {
    'columns':('startdate','starttime','subjectid','groupid','elapsedtime','computer_platform','completed',
    'radiobuttons_difficulty_response','radiobuttons_interest_response','dropdown_age_response','ageGroup',
    'nr_comissions','percept_commissions','z_commission','percentile_commission',
    'nr_omissions','percent_omissions','z_Omission','percentile_Omission',
    'count_anticipatory','z_AnticipatoryResponses','percentile_AnticipatoryResponses',
    'meanRT_go','stdRT_go','z_goRT','percentile_goRT',
    'CV_go','z_CV','percentile_CV','meanRT_GObeforesuccessNOGO','meanRT_GObeforefailedNOGO'),
    'separatefiles':True
}

#<summarydata>
# /columns = (script.startdate, script.starttime, script.subjectid, script.groupid, script.elapsedtime, computer.platform, values.completed,
# radiobuttons.difficulty.response, radiobuttons.interest.response, dropdown.age.response, values.ageGroup,
# expressions.nr_commissions, expressions.percent_commissions, values.z_commission, values.percentile_commission,
# expressions.nr_omissions, expressions.percent_omissions, values.z_Omission, values.percentile_Omission,
# values.count_anticipatory,  values.z_AnticipatoryResponses, values.percentile_AnticipatoryResponses,
# expressions.meanRT_go, expressions.stdRT_go, values.z_goRT, values.percentile_goRT,
# expressions.CV_go,  values.z_CV, values.percentile_CV,
# expressions.meanRT_GObeforesuccessNOGO, expressions.meanRT_GObeforefailedNOGO,
# )
# / separatefiles = true
# </summarydata>

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

#completed:							0 = script was not completed (prematurely aborted); 1 = script was completed (all conditions run)

#probetrial:						stores whether the current SART trial is followed by a probe (1) or not (0) (if parameters.run_mindwanderingprobe = true)
#trialtype:							"Go" (digit !=3); "NoGo" (digit == 3)
#digit:								contains the currently selected digit
#fontsize:							contains the currently (randomly) selected fontsize
#correctsuppressions:				counts number of correct suppressions (-> no response to digit 3)
#incorrectsuppressions:				counts number of incorrect suppressions or omission of response (-> no response to digit other than 3)
#count_NoGo:						counts NoGo trials (digit 3)
#count_Go:							counts Go trials (digits other than 3)
#count_validGo:						counts correct Go trials with valid latencies
#RT:								saves the response latency (in ms) unless response is suppressed. In that case values.RT = ""
#latencytype:						0 = no response given (suppression); 1 = anticipatory latency (< parameters['anticipatoryresponsetime']);
#									2 = ambiguous latency; 3 = valid latency (>= parameters['validresponsetime'])
#									Note: independent of Go-NoGo trial
#responsetype:						"NoGo Success": correctly suppressed response to NoGo trial (digit 3)
#									"Omission": incorrectly suppressed response to a Go trial (digit other than 3)
#									"NoGo Failure": any response to a NoGo trial
#									"Go Anticipatory": anticipatory response for Go trials with latencies < parameters['anticipatoryresponsetime']
#									"Go Ambiguous": ambiguous response for Go trials
#									"Go Success": valid response for Go trials with latencies >= parameters['validresponsetime']
# /count_anticipatory:				counts the number of times a G0-latency was faster than parameters['anticipatoryresponsetime']
# /sumRT_GO:							sums up the valid latencies (in ms) of correct responses (latencies >= parameters['validresponsetime'])
# /ssdiffRT_go:						sums up the squared differences between valid latencies of correct responses latencies and mean latency
# /RT1-
# /RT4:								store the last four consecutive latencies of correctly responded nondigit3 trials (irrespective of values.latencytype)

# /fourfilled:						1 = 4 consecutive latencies of correctly responded nondigit3 trials are available 
# 									0 = fewer than 4 consecutive latencies of correctly responded nondigit3 trials are available

# /count_4RTs_successsuppression:		counts how often 4 consecutive latencies of correctly responded nondigit3 trials are available before a 
# 									successfully suppressed digit3 trial
# /count_4RTs_failedsuppression:		counts how often 4 consecutive latencies of correctly responded nondigit3 trials are available before a 
# 									failed suppressed digit3 trial
# /sumRT_successsuppression:			sums up all the latencies of 4 consecutive latencies of correctly responded nondigit3 trials before a 
# 									successfully suppressed digit3 trial
# /sumRT_failedsuppression:			sums up all the latencies of 4 consecutive latencies of correctly responded nondigit3 trials before a 
# 									failed suppressed digit3 trial

# /countprobes:						counts the number of probes run


# variables returned from functions

# probetrial = 0
# trialtype = 0
# digit = 0
# fontsize = 0
#fourfilled = 0
# RT = 0
# latencytype = ""
# responsetype = 0




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

# variables that are defined within functions
# countprobes = 0
# trialnum = 0
# blockcode = 'SART'

#### From sart_norms.iqx ####  
     
# Summary Variables: z-scores and corresponding percentile variables
# z_Commission = 0
# percentile_Commission = 0
# z_Omission = 0
# percentile_Omission = 0
# z_goRT = 0
# percentile_goRT = 0
# z_CV = 0
# percentile_CV = 0
# z_AnticipatoryResponses = 0
# percentile_AnticipatoryResponses = 0
# ageGroup = 0  # stores the assigned age group (1-6) based on age response
# z_Commission = 0
# percentile_Commission = 0
# z_Omission = 0
# percentile_Omission = 0
# z_goRT = 0
# percentile_goRT = 0
# z_CV = 0
# percentile_CV = 0
# z_AnticipatoryResponses = 0
# percentile_AnticipatoryResponses = 0

###################################################################################################################
###################################################################################################################
#	LISTS
###################################################################################################################
###################################################################################################################

# Note: list created on runtime; it saves all valid latencies of correct Go trials
# in order to calculate Std of correct and valid Go-latencies

validgolatencies = []
trial_data = []
summary_data = []

# trial_data = [current_date,current_time,subject,group,blockcode,blocknum,trialcode,trialnum,trialcount,
# defaults['digitpresentationtime'], defaults['maskpresentationtime'], trialtype, digit, fontsize, 
# response, correct, RT, latency, latencytype, responsetype, count_anticipatory,
# correctsuppressions, count_NoGo, incorrectsuppressions, count_Go, count_validGo, countprobes,
# radiobuttons_difficulty_response, radiobuttons_interest_response]

# summary_data = [current_date,starttime,subjectid,groupid,elapsedtime,computer_platform,completed,
#      radiobuttons_difficulty_response,radiobuttons_interest_response,dropdown_age_response,ageGroup,
#      nr_commissions,percept_commissions,z_commission,percentile_commission,
#      nr_omissions,percent_omissions,z_Omission,percentile_Omission,
#      count_anticipatory,z_AnticipatoryResponses,percentile_AnticipatoryResponses,
#      meanRT_go,stdRT_go,z_goRT,percentile_goRT,
#      CV_go,z_CV,percentile_CV, meanRT_GObeforesuccessNOGO,meanRT_GObeforefailedNOGO]

###################################################################################################################
###################################################################################################################
#	EXPRESSIONS
###################################################################################################################
###################################################################################################################
# /percent_NoGosuccess:					percentage of correct suppressions in NoGo trials (=No go success)
# /percent_commissions:					percentage of commission errors in NoGo trials (=NoGo failures; also reported as SART errors)
# /nr_commissions:						absolute number of commissions
# /percent_omissions:						percentage of incorrect suppressions in Go trials (=omission of response)
# /nr_omissions:							absolute number of omissions

# Mean RTs are calculated for the correct consecutive (not interrupted either by a NoGo or by an omission trial) last four Go- trials (digit other than 3) preceding successful NoGo trial
# Mean RTs are calculated for the correct consecutive (not interrupted either by a NoGo or by an omission trial) last four Go- trials (digit other than 3) preceding preceding failed NoGo trial
# Note: in this script any 4 correct Go trials (=> Go trials that are responded to) are counted irrespective of values.latencytype

# /meanRT_GObeforesuccessNOGO:				mean latency of consecutive 4 correct trials before correct suppression of response to digit 3
# 											(=> a measure of speed before successful NoGo trials)
# /meanRT_GObeforefailedNOGO:					mean latency of consecutive 4 correct trials before incorrect response of response to digit 3
# 											(=> a measure of speed before failed NoGo trials)

# /meanRT_go:									mean latency (in ms) of valid and correct Go trials (latencies >= parameters['validresponsetime'])
# /stdRT_go:									estimated standard deviation (STD) of valid and correct Go trial latencies
# /CV_go:										coefficient of variablity (CV = STD/Mean) => a measure of variability independent of mean differences

# <expressions> need to remember to update these for the summary stats
# percent_NoGosuccess = 0 #(correctsuppressions/count_NoGo) # 100
# percent_commissions = 100 - percent_NoGosuccess
# nr_commissions = count_NoGo - correctsuppressions
# percent_omissions = 0 # (incorrectsuppressions/count_Go) # 100
# nr_omissions = incorrectsuppressions

# meanRT_GObeforesuccessNOGO = 0 #sumRT_successsuppression/(4*count_4RTs_successsuppression)
# meanRT_GObeforefailedNOGO = 0 # sumRT_failedsuppression/(4*count_4RTs_failedsuppression)

# meanRT_go = np.mean(validgolatencies)
# stdRT_go = np.std(validgolatencies)
# CV_go = 0 # stdRT_go/meanRT_go

# trialcount = count_Go + count_NoGo

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

practiceend_page = visual.TextStim(mywin, text=page['practiceend'],
    font=getReady_Params['fontstyle'], # To do: not sure we have the 'Symbol' font, may need to add
    units='norm',
    height = getReady_Params['size'][1], # it might be close enough like this? # ToDo
    color=(1,1,1), # white
    pos=(0,0.2))

# initialize text digit <- updated on every trial
digit = visual.TextStim(mywin, text='',
    font=defaults['fontstyle'], # To do: not sure we have the 'Symbol' font, may need to add
    units='height',
    height=defaults['fontsize'], 
    color=(1,1,1))
digit.autoDraw = False  # Automatically draw every frame

# <text digit>
# /items = ("<%values.digit%>")
# / fontstyle = ("Symbol", values.fontsize, false, false, false, false, 5, 1)
# / txcolor = white
# /txbgcolor = black
# /position = (50%, 50%)
# /erase = false
# </text>

# load the mask image
fixation = visual.ImageStim(mywin,image=mask,units='height',size=0.2)
fixation.height = 0.2

# <picture mask>
# /items = mask
# /select = 1
# /position = (50%, 50%)
# /size = (100%, parameters.maskheight)
# /erase = false
# </picture>

# Note: shape background is used to present the black background and erase the mask and achieve a steady SOA between digits
# (Note: a black background element was used rather than setting the default background 'black' in order to  
# to present radiobuttons during the (optional) mindwandering task. Radiobuttons do not show up on a default black background
# in Inquisit 4.0.7) # DON'T NEED THIS FOR PSYCHOPY

# background = Rect(mywin,width=1,heigth=1,units='norm',fillcolor=(-1,-1,-1),pos=(-1,-1))

# <shape background>
# /shape = rectangle
# /position = (50%, 50%)
# /size = (100%, 100%)
# /color = black
# /erase = false
# </shape>

errorfeedback = visual.TextStim(mywin, text='Incorrect',
    font=defaults['fontstyle'], # To do: not sure we have the 'Symbol' font, may need to add
    units='height',
    height=0.04, 
    color=(1,-1,-1), # red
    pos=(0,0))
errorfeedback.autoDraw = False  # Automatically draw every frame

# <text errorfeedback>
# /items = ("Incorrect")
# /txcolor = red
# /txbgcolor = black
# /position = (50%, 70%)
# / fontstyle = ("Arial", 5%, false, false, false, false, 5, 1)
# /erase = false
# </text>

getReady_Params = {'items': 'Get Ready: {}'.format(expressions['buttoninstruct2']),
    'fontstyle':'Arial',
    'size':(0.08,0.04)}

getReadyText = visual.TextStim(mywin, text=getReady_Params['items'],
    font=getReady_Params['fontstyle'], # To do: not sure we have the 'Symbol' font, may need to add
    units='norm',
    height = getReady_Params['size'][1], # it might be close enough like this? # ToDo
    color=(1,1,1), # white
    pos=(0,0))

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
    

def update_index(target):
    #print('Index = {} of {}'.format(target['currentindex'],len(target['items'])))
    # if we have reached the end of a list (resetinterval), reset index and shuffle (reset stimulus frames)
    if target['currentindex']==len(target['items'])-1:
        target['currentindex'] = 0
        random.shuffle(target['items'])
    else: # otherwise update the index
        target['currentindex']+=1
    return target

def createdata(suffix = ''):
    # open files, write headers, close
    raw_data_log = open('logs/G{}S{}_sart_log{}.csv'.format(group,subject,suffix),'w')
    raw_data_writer = csv.writer(raw_data_log)
    raw_data_writer.writerow(data['columns'])

    return raw_data_writer

def record_data(raw_data_writer,trial_data): # add all the variables that change on each trial. 
    # record raw data
    raw_data_writer.writerow(trial_data)
    # raw_data_log.open('w')
    # raw_data_log.writerow(trial_data)
    # raw_data_log.close()

def record_summary_data(summary_data):
    summary_data_log = open('logs/G{}S{}_sart_log.csv'.format(group,subject),'w',newline='')
    summary_data_writer = csv.writer(summary_data_log)
    summary_data_writer.writerow(summary_data['columns'])
    summary_data_writer.writerow(summary_data)
    summary_data_log.close()
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


def practice_trial():
    pretrialpause = parameters['ITI'] # get ITI for this trial

    def ontrialbegin():
        # query trial parameters
        trialtype = practice_trialtype['items'][practice_trialtype['currentindex']] 
        digitvalue = practice_digitsequence['items'][practice_digitsequence['currentindex']] 
        fontsize = practice_fontsizes['items'][practice_fontsizes['currentindex']] 

        print('trialindex = {}, fontindex = {}'.format(practice_trialtype['currentindex'],practice_fontsizes['currentindex']))

        # Update digit presentation text
        digit.height = fontsize
        digit.text = digitvalue

        # Set up digit
        digit.draw()

        # wait for the inter-trial-interval
        core.wait(pretrialpause)

        # Start recording button presses
        event.clearEvents()
        trialClock.reset()
                
        # Show digit
        mywin.flip()
        waitperiod.start(parameters['digitpresentationtime'])  # start a period of 0.5s
        # Draw fixation while mask is displayed 
        fixation.draw()
        waitperiod.complete() 
        # show mask
        mywin.flip()
        core.wait(parameters['maskpresentationtime'])
        keys = event.getKeys(keyList=["q","space"],timeStamped=trialClock) # get just the first time space was pressed        print('keys are {}'.format(keys))

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
            mywin.close()
            core.quit()
        # record overall time
        trialduration = trialClock.getTime()

        # revert to black screen
        mywin.flip(clearBuffer=True)

        return trialtype, response, latency, trialduration, digitvalue, fontsize


    def ontrialend(trialtype, response,latency):
        global practice_trialtype
        global practice_digitsequence
        global practice_fontsizes

        practice_trialtype = update_index(practice_trialtype)
        practice_digitsequence = update_index(practice_digitsequence)
        practice_fontsizes = update_index(practice_fontsizes)
        
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
        
        return RT, latencytype, responsetype, correct
   
   # run 
    trialtype, response, latency, trialduration, digitvalue, fontsize = ontrialbegin()
    RT, latencytype, responsetype, correct = ontrialend(trialtype, response,latency)
    print('latency was {}, latencytype was {}, RT was {}\n'.format(latency,latencytype,RT))
    print('responsetype was {}\n'.format(responsetype))

    if correct==0: # I invented where this should be set
        feedback()
    
    return trialtype, response, latency, trialduration, RT, latencytype, responsetype, correct, digitvalue, fontsize
# end Practice Go

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

def trial():
    pretrialpause = parameters['ITI'] # get ITI for this trial

    def ontrialbegin():
        # define global variables to update
        global count_Go
        global count_NoGo

        # query trial parameters
        trialtype = expr_trialtype['items'][expr_trialtype['currentindex']] 
        digitvalue = expr_digitsequence['items'][expr_digitsequence['currentindex']] 
        fontsize = expr_fontsizes['items'][expr_fontsizes['currentindex']] 
        dostim = expr_stimtype['items'][expr_stimtype['currentindex']]

        # update values
        if trialtype=='go':
            count_Go += 1

        elif trialtype=='nogo':
            count_NoGo += 1

        # Update digit presentation text
        digit.height = fontsize
        digit.text = digitvalue

        # Set up digit
        digit.draw()

        # wait for the inter-trial-interval
        core.wait(pretrialpause)

        # Start recording button presses
        event.clearEvents()
        trialClock.reset()
                
        # Show digit
        mywin.flip()
        waitperiod.start(parameters['digitpresentationtime'])  # start a period of 0.5s

        # STIMULATE HERE <- stimulates on digit presentation
        if dostim=='stim':
            task.write(buf, auto_start=True) 

        # Draw mask while digit is displayed 
        fixation.draw()
        waitperiod.complete() 
        # show digit
        mywin.flip()
        core.wait(parameters['maskpresentationtime'])
        keys = event.getKeys(keyList=["q","space"],timeStamped=trialClock) # get just the first time space was pressed

        # CALL SAFE STOP TO STIMULATION
        if dostim=='stim':
            task.wait_until_done()
            task.stop()

        if len(keys) > 0:
            keys = keys[0]
            response = keys[0]
            latency = round((keys[1])*1000) # convert to ms

            # check for quit key
            if response =='q':
                #raw_data_log.close()
                mywin.close()
                task.close()
                core.quit()

        else:
            response = "0"
            latency = 0

        # record overall time
        trialduration = trialClock.getTime()

        # revert to black screen
        mywin.flip(clearBuffer=True)

        return trialtype, response, latency, trialduration, digitvalue, digitvalue, fontsize

    def ontrialend(trialtype, response,latency):
        # define global variables to update
        global expr_trialtype
        global expr_stimtype
        global expr_digitsequence
        global expr_fontsizes
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

        # update indexes
        expr_trialtype = update_index(expr_trialtype)
        expr_digitsequence = update_index(expr_digitsequence)
        expr_fontsizes = update_index(expr_fontsizes)
        expr_stimtype = update_index(expr_stimtype)

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

        # # determine probe trial?? (no feedback during experiment)
        # if responsetype == "NoGo Success" or responsetype == "Go Success":
        # 	practice_error = False
        # else:
        # 	practice_error = True
        return RT, latencytype, responsetype, correct

    # run 
    trialtype, response, latency, trialduration, digitvalue, digitvalue, fontsize = ontrialbegin()
    RT, latencytype, responsetype, correct = ontrialend(trialtype, response,latency)

    return trialtype, response, latency, trialduration, RT, latencytype, responsetype, correct, digitvalue, fontsize
    

###################################################################################################################
###################################################################################################################
#	BLOCKS
###################################################################################################################
###################################################################################################################
def block_practice():
    blockcode = 'practice'
    blocknum = 0
    postinstructions = practiceend_page
    raw_data_log = createdata('_practice')
    getReady()
    
    #count_anticipatory,correctsuppressions, 
    #        count_NoGo, incorrectsuppressions, count_Go, count_validGo

    for trx in range(len(practice_digitsequence['items'])):
        trialtype, response, latency, trialduration, RT, latencytype, responsetype, correct, digitvalue, fontsize = practice_trial()
        
        # apply appropriate formatting to variables
        trialcode = trialtype.lower()
        fontsize = '{}ptc'.format(int(round(fontsize*100)))
        
        # update values
        trialnum = trx+2
        trialcount = trx+1
        trial_data = [build, computer, current_date,current_time,subject,group,blockcode,blocknum,trialcode,trialnum,trialcount,
            int(parameters['digitpresentationtime']*100), int(parameters['maskpresentationtime']*100), trialtype, digitvalue, fontsize,
            response, correct, RT, latency, latencytype, responsetype, count_anticipatory,correctsuppressions, count_NoGo, 
            incorrectsuppressions, count_Go, count_validGo, 
            0,0,0] #

            # build,computer.platform,date,time,subject,group,blockcode,blocknum,trialcode,trialnum    expressions.trialcount,
            # parameters.digitpresentationtime,parameters.maskpresentationtime,values.trialtype    values.digit,values.fontsize,
            # response,correct,values.RT,latency,values.latencytype,values.responsetype,values.count_anticipatory,values.correctsuppressions,values.count_NoGo,
            # values.incorrectsuppressions,values.count_Go,values.count_validGo,
            # values.countprobes,radiobuttons.difficulty.response,radiobuttons.interest.response

        record_data(raw_data_log,trial_data)

    #record_summary_data()

    #onblockend = expr_fontsizes.reset() # so make expr_fontsizes a class? with a method reset?

# <block practice>
# /postinstructions = (practiceend)
# /trials = [1 = getReady; 2-19 = list.practice_trialtype]
# /onblockend = [list.expr_fontsizes.reset()]
# </block>

def block_SART():
    blockcode = 'SART'
    blocknum = 1

    # bgstim = cognitiveloadsart # what is this?
    getReady()
    raw_data_log = createdata('_tvns_expr')
    for trx in range(len(expr_digitsequence['items'])):
        trialtype, response, latency, trialduration, RT, latencytype, responsetype, correct, digitvalue, fontsize = trial()
        
        # apply appropriate formatting to variables
        trialcode = trialtype.lower()
        fontsize = '{}ptc'.format(int(round(fontsize*100)))
        
        # update values
        trialnum = trx+2
        trialcount = trx+1
        trial_data = [build, computer, current_date,current_time,subject,group,blockcode,blocknum,trialcode,trialnum,trialcount,
            int(parameters['digitpresentationtime']*100), int(parameters['maskpresentationtime']*100), trialtype, digitvalue, fontsize,
            response, correct, RT, latency, latencytype, responsetype, count_anticipatory,correctsuppressions, count_NoGo, 
            incorrectsuppressions, count_Go, count_validGo, 
            0,0,0] #
        record_data(raw_data_log,trial_data)

    #record_summary_data()

# <block SART>
# / bgstim = (cognitiveloadsart)
# /trials = [1 = getReady; 2-226 = list.trialtype]
# </block>

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

    # get computer info
    computer = platform.system()

    # show instructions to participant
    preinstructions = (intro_page)
    preinstructions.draw()
    mywin.flip()
    waitForButtonPress()

    global task
    with nidaqmx.Task() as task:
        task.ao_channels.add_ao_voltage_chan("Dev1/ao1") # check output channel on DAQ
        task.timing.cfg_samp_clk_timing(params["sr"])
        

        
        block_practice()
        block_SART()
    # umm, run the experiment?
    completed = 1
    mywin.close()
    core.quit()    
expt() # run the experiment
# <expt>
# /preinstructions = (intro)
# /blocks = [1 = practice; 2 = SART]
# /onexptend = [values.completed = 1]
# </expt>

# WLS: Monkey is a random distribution used for testing scripts. 

# <monkey>
# / latencydistribution = normal(300, 250)
# </monkey>


##############################################################################################################
#												End of File
##############################################################################################################
