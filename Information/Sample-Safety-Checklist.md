# Overview 

In working with electricity, the utmost care must be taken to ensure that stimulation is  delivered safely. This is true for all participants, but especially for sensitive patient populations, it is crucial to follow all safety measures. While the equipement includes current and voltage limiting circuits that minimize the possibility of adverse events, procedures should be followed carefully as if these fall-back measures were not in place. Act as if once the electrodes are connected between a participant and the stimulator, the potential exists for delivering a painful shock.

Review the general safety measures prior to each stimulation session and follow this checklist during the protocol. Above all:

 <center> <font size="10"> NEVER RUSH </font> </center>

## If a problem occurs at any step: STOP-SWITCH-REMOVE: 

1) STOP the script, 
2) SWITCH to Voltage mode, 
3) REMOVE electrodes (disconnect from stimulator or remove from participant)

## General Safety Measures

- DISCONNECT ELECTRODES: The easiest way to ensure that the participant does not receive an unintended shock is to not attach the electrodes to the stimulator until just before you are ready to stimulate (see note about pause points below).

- USE CURRENT/VOLTAGE LIMITING CABLES: The limiting cable caps output at 3mA. The voltage limiting cable caps voltage at 30v. 

- DON'T CHANGE CONNECTIONS WHILE PARTICIPANT IS CONNECTED TO STIMULATOR: Plugging in / unplugging things can lead to surges in power. 

- USE THE CHECKLISTS: Following these steps in order in each session will reduce the chance of human error. 

## Equipment Setup Checklist (all items to be checked off prior to preparing patient/participant) - MATLAB

1. Electrodes are not attached to the stimulator or patient. 
2. STMISOLA stimulator is plugged into external battery, turn On, set mode to V (Voltage) and resistance (yellow switch) to 1kOhm. Hold Reset button for 3 seconds until Red light turns off.
3. Two-Tinned Wire is securely connected to 3.5mm audio jack to AO1 (analog out 1) and AO GND (ground) on DAQ card.
4. STMISOLA audio cable is plugged into 3.5mm audio jack of Two-Tinned Wire (-> USB)
5. DAQ card is plugged into task laptop via USB. 
6. On front of stimulator, Current Limiting Circuit is plugged into (+).
7. Open Matlab (>=2014b) to folder containing stimulation scripts, and open singleStimTrain.m, singleStaircase.m. Make sure that the line containing ???addAnalogOutputChannel??? points to Device ID to the ID of the National Instruments USB device (e.g., ???Dev4???)
8. Safety Check: Enter the following command: singleStimTrain(1,100,25,15). Red light on stimulator should flicker on, indicating that voltage is being sent to the stimulator. 
9. Connect speakers to Laptop output and check volume. 

## Equipment Setup Checklist (all items to be checked off prior to preparing patient/participant) - PYTHON

1. Electrodes are not attached to the stimulator or patient. 
2. STMISOLA stimulator is plugged into external battery, turn On, set mode to V (Voltage) and resistance (yellow switch) to 1kOhm. Hold Reset button for 3 seconds until Red light turns off.
3. Two-Tinned Wire is securely connected to 3.5mm audio jack to AO1 (analog out 1; red wire) and AO GND (ground; black wire) on DAQ card.
4. STMISOLA audio cable is plugged into 3.5mm audio jack of Two-Tinned Wire (-> USB)
5. DAQ card is plugged into task laptop via USB. 
6. On front of stimulator, Current Limiting Circuit is plugged into (+).
7. Open Matlab (>=2014b) to folder containing stimulation scripts, and open singleStimTrain.m, singleStaircase.m. Make sure that the line containing ???addAnalogOutputChannel??? points to Device ID to the ID of the National Instruments USB device (e.g., ???Dev4???)
8. Safety Check: Enter the following command: singleStimTrain(1,100,25,15). Red light on stimulator should flicker on, indicating that voltage is being sent to the stimulator. 
9. Connect speakers to Laptop output and check volume. 

## Participant Prep Checklist (all items to be checked off prior to connecting electrode leads) - (Refer to taVNS_Participant_Prep_Flowchart.jpeg)
1. Make sure that electrode leads are NOT connected to stimulator.
2. Check whether procedure and all risks involved have been explained to participant/patient, and that they have signed Consent/HIPAA.
3. Clean participant/patient???s ear with alcohol (wipe, swab).
4. Abrade participant's ear using Q-Tip (NuPrep optional)
5. Make a mold of participant/patient???s ear using putty. 
6. Affix electrodes to putty and add a dollop of Gel 104 to each disc. 
7. Affix electrodes firmly to target auricular sites using putty. 
8. Check whether participant is comfortable and ready to begin. Make sure laptop and stimulator are not facing participant. 

## Thresholding Checklist - MATLAB
1. Ensure that electrodes are not attached to the stimulator.
2. Ensure that stimulator is On and set to Voltage (V) / 1kOhm mode.
3. Plug in electrodes and conduct impedance test (quickly switch to Current mode and back, while watching whether red indicator light came on). 
    - If red light shines brightly, this indicates that impedance may be too high, which will limit effective stimulation. First, press putty/electrodes in more firmly and repeat impedance test. If red light still comes on, remove electrodes and start participant prep over from scratch.
5. Tell the participant that you are going to find the right level to stimulate at for the experiment. To do so, stimulation will slowly increase in strength. Tell the participan to let you know (either verbally or by raising a hand) if they feel anything. Stimulation can feel like a tickling, tapping, or sudden warming sensation (or something else unique to the individual). Tell them to only respond if they are certain that they noticed the stimulation (false positives can often occur). 
6.  Run singleStaircase.m. Pulse Width should be set to 200. Wait a moment for the script to start, then press the 1 key to deliver the first stimulation train. Slowly continue pressing (1) until the participant reports feeling stimulation (referred to as a 'reversal'). When that occurs, press (2). The amplitude will be reduced by -0.3mA, and then increased by 0.1mA on each successive stimulation train. The script exits after eight reversals and displays the participant's threshold in the main window. 
    - The MATLAB version depends on having the window displaying numbers highlighted in order to record a button press. If this window disappears, hover the mouse over the Matlab icon and click on the appropriate window to bring it to the foreground. 
7. When script is complete, switch to Voltage mode.
8. Use singlestimtrain.m to test to whether the participant can feel stimulation at the target level. "AMP" should be set to -0.2mA below the participant's threshold. 
    - Call to function is `singleStimTrain(AMP, 30, 200, 15)`
9. Switch to voltage mode (if haven???t done so already)
10. Record the participant's threshold. 

## Disconnecting Checklist
1. Ensure that script has finished running.
2. Ensure that red indicator light is dark (no voltage is being sent).
3. Switch stimulator to Voltage mode.
4. Disconnect electrodes from participant.
5. Turn stimulator off.
6. Gently clean electrodes using lukewarm water, soap, and toothbrush. Dry using paper towel or hang to dry. 
