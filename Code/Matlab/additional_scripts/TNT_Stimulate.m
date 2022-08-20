%% TNT_Stimulate
% This is the primary tVNS script. It loads a 
% trial matrix from a .csv file. This file specifies the parameters
% for each trial, based on the participant's perceptual thresholds, 
% as well as the inter-trial-interval for each trial.

% The script multiRandomStaircase.m should always be run just prior to 
% running this script. If the electrodes are moved or adjusted, 
% this may lead to a change in impedance and consequently a change 
% in the threshold. 

% Reminder to be in voltage mode
prompt = 'For safety, switch to Voltage mode and remove electrodes whenever stimulation is not being applied. ';
x = input(prompt);

% get rid of prior data
clear all;
close all;

% Prompt for input of filename (subject name), condition list, and other parameters
prompt = {'Enter Filename:', 'Enter Condition List Number', 'Enter 300pw Threshold', 'Enter 500pw Threshold'};
dlg_title = 'Input';
num_lines = 1;
defaultans = {'test.csv', '1', '1', '1'};
userData = inputdlg(prompt,dlg_title,num_lines,defaultans);

% convert to usable format
fileName=cell2mat(userData(1));
condListNum = str2num(cell2mat(userData(2)));
percept_300_thres = str2double(cell2mat(userData(3)));
percept_500_thres = str2double(cell2mat(userData(4)));

%% set up DAQ card
% requires nidaqmx drivers to have been installed on this computer. 
Stim = daq.createSession('ni'); % creates a session for communicate with DAQ

% The second argument of addAnalogOutputChannel 
% needs to be set according to the label assigned 
% to the DAQ card by your system
addAnalogOutputChannel(Stim,'Dev1',1,'Voltage'); % adds a channel
% with the handle Stim to the DAQs AO1 port. 


%% Global Parameters
params.hard_iti = 2.8; % at least 2.8 seconds between trains
params.sr = 24000; % sampling frequency
params.npulses = 15; % number of pulses in pulse train

%% import trial matrix
% abs_cond_iti is reasonable for recording GSR responses.
% abs_ecog_iti has much faster ITIs
load(sprintf('abs_ecog_iti/abs_ecog_iti_%d', condListNum));
trialMatrix = iout;
params.ntrials = size(trialMatrix,1);


%% Configure DAQ for stimulation
% set session rate
Stim.Rate = params.sr;

% set output voltage signal to 0, before plugging in electrodes/switching to Current Mode
outputSingleScan(Stim, 0);


% prompt to begin
prompt = 'You may now plug in the electrodes and switch to Current Mode. Press Enter to begin.';
x = input(prompt);

% capture Timers 
trialTimer = tic;
triggerTimer = tic;
loadTimer = tic;

for cur_trial = 1:params.ntrials
  trialTime = toc(trialTimer); % mark beginning of trial

  curCondition = trialMatrix{cur_trial,1}; % extract condition information
  curITI = trialMatrix{cur_trial,2}; % extract ITI
  C = strsplit(curCondition,'_'); % separate different parameters

  % configure stimulation waveform
  params.pw = str2double(C{3}); % pulse width (us)
  params.freq = str2double(C{4}); % frequency of stim (Hz)
  params.duration_test = params.npulses/params.freq; % duration of pulse train (s)

  %disp(params.duration_test)
  amplitude_modifier = str2double(C{2})/10; % amplitude above and below threshold
  if params.pw == 300
    params.amp = percept_300_thres + amplitude_modifier; 
  else
    params.amp = percept_500_thres + amplitude_modifier;
  end

  % Generate stimulus waveform
  buf = MakeStimBuffer(params); % generate the stimulation waveform

  % make and load the buffer to the DAQ
  queueOutputData(Stim, buf'); % loads buffer to the DAQ
  loadTime = toc(loadTimer); % keep track of time between trial onset and buffer loading

  % stimulate
  trigTime = toc(triggerTimer); % get time when stimulus is triggered
  Stim.startForeground         % stim on, this halts all other operations

  % wait for the appropriate amount of time - time passed for stimulation.
  WaitSecs(params.hard_iti - params.duration_test + curITI);  % it may be that we want to use a loop as well, due to timing issues with loading the buffer? or load buffer after the trial? I don't know if it pauses time.

  %pause(params.hard_iti - params.duration_test + curITI);

  % update trial Matrix
  trialMatrix{cur_trial,4} = trialTime;
  trialMatrix{cur_trial,5} = trigTime;
  trialMatrix{cur_trial,6} = loadTime;

end


% save the trial matrix with recorded times
save(strcat(fileName(1:end-4), '_trialMatrix.mat'),'trialMatrix');

disp('Switch to Voltage Mode and then remove the electrodes.')
