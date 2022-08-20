% FFR_playsound_and_stimulate.m
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
prompt = {'Enter Filename:', 'Enter Threshold'};
dlg_title = 'Input';
num_lines = 1;
defaultans = {'test.csv', '1'};
userData = inputdlg(prompt,dlg_title,num_lines,defaultans);

% convert to usable format
fileName=cell2mat(userData(1));
percept_thres = str2double(cell2mat(userData(2)));

%% set up DAQ card
% requires nidaqmx drivers to have been installed on this computer.
Stim = daq.createSession('ni'); % creates a session for communicate with DAQ

% The second argument of addAnalogOutputChannel
% needs to be set according to the label assigned
% to the DAQ card by your system
addAnalogOutputChannel(Stim,'DAQ_ID',1,'Voltage'); % adds a channel
% with the handle Stim to the DAQs AO1 port.

%% Configure sound
% read in the sound file that will be played.
[wavedata fs ] = audioread('auditory_stimuli/s1_2_100.wav'); % load sound file (make sure that it is in the same folder as this script
InitializePsychSound(1); %inidializes sound driver...the 1 pushes for low latency
pahandle = PsychPortAudio('Open', [], [], 2, fs, 1, 0); % opens sound buffer frequency
soundTime = length(wavedata) ./ fs ; % in seconds
% need to take any padding silence into account
% looks like 10ms of padding

%% Global Parameters
params.hard_iti = 2.8; % need to set this
params.sr = fs; % sampling frequency is same as wave frequency (hopefully will work)

%% create trial matrix
% abs_cond_iti is reasonable for recording GSR responses.
% abs_ecog_iti has much faster ITIs
params.ntrials=4000;
params.iti = 0.13;
block_pause = params.ntrials/2;
% stim on/off, jitter, trialTimer
trialMatrix = [zeros(params.ntrials, 1) zeros(params.ntrials, 1) zeros(params.ntrials, 1) zeros(params.ntrials, 1)];

jitter_flag = true;
if jitter_flag == true % if you do want jitter between trials
	max_jitter = 0.148;
	min_jitter = 0.122;
    jitter_step_size = 0.001;
	jitter_vec = min_jitter:jitter_step_size:max_jitter;
	for i = 1:size(trialMatrix,1)
		trialMatrix(i,2) = datasample(jitter_vec,1);
	end
else % if you don't want any jitter between trials
	trialMatrix(:,2) = repmat(params.iti,params.ntrials,1);
end


%% Configure DAQ for stimulation
% set session rate
Stim.Rate = params.sr;

% set output voltage signal to 0, before plugging in electrodes/switching to Current Mode
outputSingleScan(Stim, 0);
PsychPortAudio('FillBuffer', pahandle, wavedata'); % loads data into buffer


% configure stimulation waveform
params.pw2 = 300; % pulse width (us)
params.freq1 = 25; % frequency of stim (Hz)
params.duration_test = soundTime; % duration of pulse train (s)
params.amp = percept_thres - 0.2; % set amplitude to 0.2mA under percept threshold

% Generate stimulus waveform
buf = MakeStimBuffer(params); % generate the stimulation waveform

% make and load the buffer to the DAQ
queueOutputData(Stim, buf'); % loads buffer to the DAQ

% prompt to begin
prompt = 'You may now plug in the electrodes and switch to Current Mode. Press Enter to begin.';
x = input(prompt);

% capture Timers
trialTimer = tic;
itiTimer = tic;

for cur_trial = 1:params.ntrials
  trialTime = toc(trialTimer); % mark beginning of trial

  cur_iti = trialMatrix(cur_trial,2);

  % if current trial is in first block (half of all trials) don't stimulate
  if cur_trial <= params.ntrials/2
  	measuredITI = toc(itiTimer);
  	trialMatrix(cur_trial,4) = measuredITI;

  	% start auditory playback
  	PsychPortAudio('Start', pahandle, 1,0); %starts sound immediateley
  	WaitSecs(soundTime);  % it may be that we want to use a loop as well, due to timing issues with loading the buffer? or load buffer after the trial? I don't know if it pauses time.
  	PsychPortAudio('Stop', pahandle);% Stop sound playback
  	itiTimer = tic;
  	WaitSecs(cur_iti);
  else
  	measuredITI = toc(itiTimer);
  	trialMatrix(cur_trial,4) = measuredITI;
    % start auditory playback
    PsychPortAudio('Start', pahandle, 1,0); %starts sound immediatley
    % stimulate
    Stim.startForeground         % stim on, this halts all other operations
    PsychPortAudio('Stop', pahandle);% Stop sound playback
    itiTimer = tic;

    % reload the buffer
    loadTimer = tic;
    queueOutputData(Stim, buf'); % loads buffer to the DAQ
    loadTime = toc(loadTimer); % keep track of time it takes to load buffer
    WaitSecs(cur_iti - loadTime); % wait the ITI - time it took to load the buffer
  end

  % update trial Matrix
  trialMatrix(cur_trial,3) = trialTime;

  if cur_trial == block_pause
  	prompt = 'Block 1 completed, press Enter to start Block 2';
	x = input(prompt);
  end

end


% save the trial matrix with recorded times
save(strcat(fileName(1:end-4), '_trialMatrix.mat'),'trialMatrix');

PsychPortAudio('Close', pahandle);% Close the audio device:

disp('Switch to Voltage Mode and then remove the electrodes.')
