
# Overview for SART task with taVNS

The first step in running the SART task (and any other taVNS experiment) is to determine the perceptual threshold for taVNS stimulation for a particular participant.

Within this folder, there is a file called taVNS_plus_SART_expr.psyrun. Double click this file and Psychopy will start up, and after a long splash-loading screen, will show a file selection screen that is empty. 

![alt text](psychopy_gui.png "Psychopy GUI")

- Click on File --> Open list
- Select taVNS_plus_SART_expr.psyrun (the same file you originally clicked on)

This will load two lines to the Psychopy Runner interface:
1. taVNS_Staircase.py
2. SART_taVNS.py

## 1. Identifying the perceptual threshold

Click on the `taVNS_Staircase.py` line, and on the right panel the white arrow within the green circle will become selectable. Clicking on this button with run the selected script. When the script runs, you should see the following input screen. 

![alt text](Staircase_intro_gui.png "Staircase GUI")

- *amplitude*: should be set to 0.1 to begin. 
- *debug*: should be unchecked (check this box to run without any stimulation)
- *group*: if using a group name (e.g., the name of the experiment), fill this in here, otherwise leave 0
- *pulse width*: use the default value of 200 for determining the threshold
- *subject*: the unique identifier for the participant

After entering the unique participant identifier in the subject field, click \*OK\* to begin the staircase. 

The screen will turn black, after which the following instructions will appear:

"You will receive brief bursts of tVNS. This can feel like a sudden warming, tingling, or tapping sensation. When prompted, press 2 if you felt the tVNS, and 1 if you did not. Only press 2 if you are certain that you felt something. If unsure, press 1. Press space to begin."

After pressing space, the screen with show a fixation cross ('+'). This indicates that stimulation is occurring. 

Following stimulation, the participant will be presented with two choices: "1 = I didn't feel it.   2 = I felt it."

