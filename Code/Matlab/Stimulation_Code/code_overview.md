# Overview of Matlab taVNS Code

This folder contains scripts for controlling the STMISOLA stimulator for taVNS experiments. 

## Core functions
1. MakeStimBuffer.m - creates a stimulation buffer (what is sent to the stimulator)
1a. biphasic_waveform.m - creates the biphasic waveform
1b. constant_rate_pulser.m - generates a series of pulses at the stimulation frequency
1b. convolve.m - convolves the biphasic waveform with the constant_rate_pulser
2. MakeStimBuffer_sinewave.m - creates a sinewave stimulation buffer
3. plotSampleWaveform.m - plots either a square-wave or sine-wave stimulation buffer
4. singleStimTrain - delivers a single burst of square-biphasic stimulation
5. singleStimTrainPlusSound - delivers a single burst of stimulation accompanied by an auditory stimulus
6. singleStimTrainSineWave - deliverse single burst of sinewave stimulation

## Core scripts
1. singleStaircase.m - determines the perceptual threshold for a biphasic waveform. 
2. singleStaircaseSineWave.m - determines perceptual threshold for a sinewave waveform
3. repeated_stimulation.m - repeatedly stimulates for a given amount of time. 