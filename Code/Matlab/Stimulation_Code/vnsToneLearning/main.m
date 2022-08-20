
%% VNS specific setup
addpath('C:\Users\chang\Documents\MATLAB\Current_Stimulation_Code')

% Reminder to be in voltage mode
prompt = 'For safety, switch to Voltage mode and remove electrodes whenever stimulation is not being applied. ';
x = input(prompt);

% get rid of prior data
clear all;
close all;

%% set up DAQ card
% requires nidaqmx drivers to have been installed on this computer.
Stim = daq.createSession('ni'); % creates a session for communicate with DAQ

% The second argument of addAnalogOutputChannel
% needs to be set according to the label assigned
% to the DAQ card by your system
addAnalogOutputChannel(Stim,'Dev1',1,'Voltage'); % adds a channel
% with the handle Stim to the DAQs AO1 port.


%% Global Parameters
params.sr = 24000.00; % sampling frequency is same as wave frequency 


%% Configure DAQ for stimulation
% set session rate
Stim.Rate = params.sr;


% set output voltage signal to 0, before plugging in electrodes/switching to Current Mode
outputSingleScan(Stim, 0);


%% Setup for experiment

% Get Subject Number
  sub = input(' Subject Number : ');
  day = input(' Day : ');
  percept_thres = input(' Perceptual Threshold : ');

% Create data file
  outfile = [cd '/data/vnsTone_' num2str(sub) '_Day_' num2str(day) '.dat'];

% configure stimulation waveform
params.pw = 300; % pulse width (us)
params.freq = 25; % frequency of stim (Hz)
params.npulses = 15; % number of pulses in pulse train
params.duration_test = params.npulses/params.freq; % duration of pulse train (s)
params.amp = percept_thres - 0.2; % set amplitude to 0.2mA under percept threshold

% Generate stimulus waveform
buf = MakeStimBuffer(params); % generate the stimulation waveform


% make and load the buffer to the DAQ
queueOutputData(Stim, buf'); % loads buffer to the DAQ

% prompt to begin
prompt = 'You may now plug in the electrodes and switch to Current Mode. Press Enter to begin.';
x = input(prompt);


%% General Setup

  clc

  warning('off')
  PsychJavaTrouble
  Screen('Preference', 'SkipSyncTests',1);

  rand('seed',sum(100*clock))


% Prevents overwriting an existing file
  if exist(outfile,'file')
    error(['The file ' outfile ' already exists.']);
  end

  fid = fopen([outfile],'w');

  speedup = 1;

% Load data
  expDir = pwd;                                                             % Set experiment directory
  dataDirectory = [expDir filesep 'data'];                                         % Set data directory within expDirectory
  trainingDirectory = [expDir filesep 'stim'];                                     % Training sound file location

% oVol = SoundVolume;
  newVol=SoundVolume(.5);

% We open the screen
% Get the screen size
  sSize = get(0, 'Screensize');
  xSize = sSize(3);                                                         % length of the x-dim of the screen
  ySize = sSize(4);                                                         % length of the y-dim of the screen

% Open window if window doesn't exist
  if ~exist('window','var')
  [window, screenRect] = Screen(0,'OpenWindow');
  HideCursor;
  end

% Cumulative point total
  boxX1 = .85*xSize;
  boxX2 = .95*xSize;
  boxY1 = .10*ySize;
  boxY2 = .20*ySize;

% Define center of screen
% rect = screenRect;
  rect = sSize;
  Xorigin = (rect(3)-rect(1))/2;
  Yorigin = (rect(4)-rect(2))/2;

% Specify color values
  white = [255 255 255];

% gray = [128 128 128];
  black = [0 0 0];
  backcolor=black;
  textcolor=white;

% Default text size and font type
  textsize=24;
  Screen(window,'TextFont','Verdana'); % Set text font

% Start things up
  begin_experiment;

  Screen('TextSize', window, 24);
  DrawFormattedText(window, 'In this experiment, you will be asked to categorize sounds into one of four categories', 'center', Yorigin-300, white);
  DrawFormattedText(window, 'You will press either "1", "2", "3" or "4".', 'center', Yorigin-200, white);
  DrawFormattedText(window, 'You will have to make guesses at first,', 'center', Yorigin-100, white);
  DrawFormattedText(window, 'but over time you will begin to learn which sounds go in each category.', 'center', Yorigin, white);
  DrawFormattedText(window, 'After each response, you will be told whether you were correct or incorrect.', 'center', Yorigin+100, white);
  DrawFormattedText(window, 'Please press the spacebar to continue.', 'center', Yorigin+250, white);
  Screen('Flip', window);
  getResp('space');
  Screen(window,'FillRect', backcolor);
  Screen('Flip', window);

  trialN = 0;

% Generate .wav file name array
  syl = {'bu', 'di', 'lu', 'ma', 'mi'};                                     % Set array designating which syllable
  speak = {'a', 'i'};                                                       % Set array designating which speaker
  speak2 = {'b', 'h'};                                                      % Secondary array for generalization block
  iidum = 1;                                                                % Set dummy variable
  iidum2 = 1;

  for i=1:length(syl)
    for j=1:4
        for k=1:length(speak)
            wavArray{iidum} = [syl{i}, num2str(j), '-', speak{k}, 'N.wav'];     % filenames for training: 2 speakers
            iidum = iidum+1;
        end
        for m=1:length(speak2)
            wavArray2{iidum2} = [syl{i}, num2str(j), '-', speak2{m}, 'N.wav'];  % filenames for generalization: 2 speakers
            iidum2 = iidum2+1;
        end
    end
  end


%% Training phase

   for blockN=1:6

     % Randomize the stimuli for this block
     randVar = randperm(length(wavArray));

     % Clear the screen for instructions
     Screen(window,'FillRect', backcolor);

     % Display inter-block instructions
      if blockN~=1
        instructions = {'Press the space bar when you are ready to continue.'};
        strLength=length(instructions); % Determine length of string for centering purposes
        for k = 1:strLength % Cycle through character string
            Screen(window,'TextSize',textsize);
            Screen(window,'DrawText',instructions{k},Xorigin-300,Yorigin+(textsize+5)*(k-1),textcolor);
            Screen('Flip', window);
        end

        getResp('space'); % Wait for user to press 'space bar';
      end
      Screen(window,'FillRect',backcolor);

     % Do the actual trials for each block
     for i=randVar

        trialN = trialN + 1;

        Screen(window,'DrawText','+',Xorigin,Yorigin+(textsize+5),textcolor); % fixation cross
        Screen('Flip', window);

        wavStr = wavArray{i};                                               % Get .wav file name
        fileStr = [trainingDirectory filesep wavStr];                           % Define full directory call string
        corrResp = wavStr(3);                                               % Define correct response number based on file name as a string
        nCR = str2double(corrResp);

        Screen(window,'FillRect', backcolor, [0 boxY2 boxX1-5 ySize]);      % Clear middle of screen
        Screen(window,'TextSize',textsize);
        Screen(window,'DrawText', 'Which Category?', Xorigin-100,Yorigin-100+(textsize+5),textcolor);
        Screen('Flip', window);



        [y,Fs] = audioread(fileStr);                                          % Read .wav file


        Stim.startBackground;                                               % stim on, this does not halt other operations
        WaitSecs(0.05);                                                     % Wait 50 ms before starting the sound file

        p = audioplayer(y,Fs);                                              % Play .wav file
        play(p, [1 (get(p, 'SampleRate') * 3)]);

        WaitSecs(params.duration_test - 0.05);                              % in case the sound file doesn't end on its own
        Stim.stop()

        queueOutputData(Stim, buf');                                        % reload buffer to the DAQ

        [Response, RT] = getResp('1!', '2@', '3#', '4$','esc');
        WaitSecs(0.1) % so the screen doesn't show up too quickly
        Screen(window,'FillRect', backcolor, [0 boxY2 boxX1-5 ySize]);      % Clear middle of screen
        Screen('Flip', window);
        vResp = Response+1;

        % Generate Feedback Text
        if Response+1==nCR
            Screen(window,'FillRect', backcolor, [0 boxY2 boxX1-5 ySize]);  % Clear middle of screen
            Screen(window,'TextSize',textsize);
            corrFeed=['Correct!'];
            Screen(window,'DrawText',corrFeed,Xorigin-50,Yorigin-50+(textsize+5),textcolor);
            Screen('Flip', window);
            pause(speedup*1);
        else
            Screen(window,'FillRect', backcolor, [0 boxY2 boxX1-5 ySize]);  % Clear middle of screen
            Screen(window,'TextSize',textsize);
            incorrFeed=['Incorrect. '];
            Screen(window,'DrawText',incorrFeed,Xorigin-50,Yorigin-50+(textsize+5),textcolor);
            Screen('Flip', window);
            pause(speedup*1);
        end

        Screen(window,'FillRect',backcolor, [0 boxY2 boxX1-5 ySize]);       % Clear middle of screen
        Screen(window, 'DrawText','+', Xorigin,Yorigin+(textsize+5),textcolor);
        Screen('Flip', window);

        tic
        data{trialN,1} = blockN;
        data{trialN,2} = trialN;
        data{trialN,3} = [wavStr '.wav'];
        data{trialN,4} = wavStr(1:2);                                       % Put syllable into data array
        data{trialN,5} = wavStr(5);                                         % Put speaker into data array
        data{trialN,6} = nCR;                                               % Put correct response into data array
        data{trialN,7} = vResp;                                             % Put actual response into data file
        data{trialN,8} = RT;                                                % Response Time
        t1=toc;
        pause(1-t1);                                                        % Pause 1s for the ITI
    end

   end


%% Generalization phase

   for blockN = 7

     % Randomize the stimuli for this block
     randVar = randperm(length(wavArray2));

     % Clear the screen for instructions
     Screen(window,'FillRect', backcolor);

     % Display inter-block instructions
     DrawFormattedText(window, 'Now you will not be told whether your responses are correct.', 'center', Yorigin-300, white);
     DrawFormattedText(window, 'Press the space bar when you are ready to start.', 'center', Yorigin-200, white);
     Screen('Flip', window);
     getResp('space');                                                      % Wait for user to press 'space bar';
     Screen(window,'FillRect',backcolor);

     % Do the actual trials for each block
     for i=randVar

        trialN = trialN+1;

        Screen(window,'TextSize',textsize);
        Screen(window,'DrawText','+',Xorigin,Yorigin+(textsize+5),textcolor);
        Screen('Flip', window);

        wavStr = wavArray2{i};                                              % Get .wav file name
        fileStr = [trainingDirectory '/' wavStr];                           % Define full directory call string
        corrResp = wavStr(3);                                               % Define correct response number based on file name as a string
        nCR=str2double(corrResp);

        Screen(window,'FillRect', backcolor, [0 boxY2 boxX1-5 ySize]);      % Clear middle of screen
        Screen(window,'DrawText', 'Which Category?', Xorigin-100,Yorigin-100+(textsize+5),textcolor);
        Screen('Flip', window);

        [y,Fs] = audioread(fileStr);                                          % Read .wav file


        Stim.startBackground;                                               % stim on, this does not halt other operations
        WaitSecs(0.05);                                                     % Wait 50 ms before starting the sound file

        p = audioplayer(y,Fs);                                              % Play .wav file
        play(p, [1 (get(p, 'SampleRate') * 3)]);

        WaitSecs(params.duration_test - 0.05);                              % in case the sound file doesn't end on its own
        Stim.stop()

        queueOutputData(Stim, buf');                                        % reload buffer to the DAQ

        [Response, RT] = getResp('1!', '2@', '3#', '4$');
        WaitSecs(0.1);
        Screen(window,'FillRect', backcolor, [0 boxY2 boxX1-5 ySize]);      % Clear middle of screen
        Screen('Flip', window);

        vResp=Response+1;

        Screen(window,'FillRect', backcolor, [0 boxY2 boxX1-5 ySize]);      % Clear middle of screen
        Screen(window, 'DrawText', '+', Xorigin,Yorigin+(textsize+5),textcolor);
        Screen('Flip', window);

        tic
        data{trialN,1} = blockN;
        data{trialN,2} = trialN;
        data{trialN,3} = [wavStr '.wav'];
        data{trialN,4} = wavStr(1:2);                                       % Put syllable into data array
        data{trialN,5} = wavStr(5);                                         % Put speaker into data array
        data{trialN,6} = nCR;                                               % Put correct response into data array
        data{trialN,7} = vResp;                                             % Put actual response into data file
        data{trialN,8} = RT;                                                % Response Time
        t1=toc;
        pause(1-t1);                                                        % Pause 1s for the ITI

     end

   end

end_experiment;

filename = ['vnsTone' '_sub' num2str(sub) '_day' num2str(day) '.mat'];
cd(dataDirectory);
save(filename,'data');

% close things up
ListenChar(0);
ShowCursor;
Screen('CloseAll');
fclose(fid);

disp('Switch to Voltage Mode and then remove the electrodes.')
