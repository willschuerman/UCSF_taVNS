%% TNT_Stimulate
% This is the primary tVNS script. It loads a
% trial matrix from a .csv file. This file specifies the parameters
% for each trial, based on the participant's perceptual thresholds,
% as well as the inter-trial-interval for each trial.

% The script multiRandomStaircase.m should always be run just prior to
% running this script. If the electrodes are moved or adjusted,
% this may lead to a change in impedance and consequently a change
% in the threshold.


% get rid of prior data
clear all;
close all;


% Prompt for input of filename (subject name), condition list, and other parameters
prompt = {'Enter Participant ID:','Enter Current (mA):', 'Enter Frequency (Hz):', 'Enter Pulse Width (us):', 'Enter number of trials:'};
dlg_title = 'Input';
num_lines = 1;
defaultans = {'000', '1','30','250','50'};
userData = inputdlg(prompt,dlg_title,num_lines,defaultans);


% convert to usable format
subjID = str2num(cell2mat(userData(1)));
params.amp = str2num(cell2mat(userData(2)));
params.freq = str2double(cell2mat(userData(3)));
params.pw = str2double(cell2mat(userData(4)));
params.ntrials = str2num(cell2mat(userData(5)));

%% set up DAQ card
% requires nidaqmx drivers to have been installed on this computer.
Stim = daq.createSession('ni'); % creates a session for communicate with DAQ

% The second argument of addAnalogOutputChannel
% needs to be set according to the label assigned
% to the DAQ card by your system
addAnalogOutputChannel(Stim,'Dev1',1,'Voltage'); % adds a channel
% with the handle Stim to the DAQs AO1 port.


%% Global Parameters
params.onTime = 7; % 7 seconds fully on
params.rampTime = 2; % 2 second ramp.
params.offTime = 12-params.rampTime*2; % 12 seconds off, though includes the ramp cycles
params.sr = 24000; % sampling frequency <- should be same as ANIN sampling frequency.

%% configure duty cycle
params.duration_test = params.rampTime + params.onTime + params.rampTime; % duration of pulse train (s)

% Generate stimulus waveform
buf = MakeStimBuffer(params); % generate the stimulation waveform

% Modify buffer to include ramp periods
onMultiplier = linspace(0,1,2*params.sr) % linear ramp from 0 to 1 for the number of samples in the ramp
offMultiplier = linspace(1,0,2*params.sr) % linear ramp from 1 to 0 for the number of samples in the ramp

buf(1:2*params.sr) = buf(1:2*params.sr).*onMultiplier % create onRamp
buf(end-(2*params.sr)+1:end) = buf(end-(2*params.sr)+1:end).*offMultiplier % create offRamp

%plot(buf) % just to check


%% Configure DAQ for stimulation
% set session rate
Stim.Rate = params.sr;

% set output voltage signal to 0, before plugging in electrodes/switching to Current Mode
outputSingleScan(Stim, 0);

% create trial Matrix
trialMatrix = zeros(params.ntrials, 7);

% prompt to begin
prompt = 'You may now switch to Current Mode. Press Enter to begin.';
x = input(prompt);

% capture Timers
stimOnTimer = tic;
stimOffTimer = tic;

% load buffer
queueOutputData(Stim, buf'); % loads buffer to the DAQ

%% run stimulation

for cur_trial = 1:params.ntrials

  % stimulate
  stimOnTime = toc(stimOnTimer); % get time when stimulus is triggered
  Stim.startForeground         % stim on, this halts all other operations
  stimOffTime = toc(stimOffTimer); % get time when stimulus is finished

  % reload buffer
  queueOutputData(Stim, buf'); % loads buffer to the DAQ

  % wait for the offcycle
  WaitSecs(params.offTime);  % it may be that we want to use a loop as well, due to timing issues with loading the buffer? or load buffer after the trial? I don't know if it pauses time.

  % update trial Matrix
  trialMatrix(cur_trial,1) = subjID;
  trialMatrix(cur_trial,2) = cur_trial;
  trialMatrix(cur_trial,3) = params.amp;
  trialMatrix(cur_trial,4) = params.freq;
  trialMatrix(cur_trial,5) = params.pw;
  trialMatrix(cur_trial,6) = stimOnTime;
  trialMatrix(cur_trial,7) = stimOffTime;
end

% save the trial matrix with recorded times
save(sprintf('PT%d_trialMatrix.mat',subjID),'trialMatrix');

disp('Switch to Voltage Mode and then remove the electrodes.')
