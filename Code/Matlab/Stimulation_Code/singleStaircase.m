% singleStaircase
%%% script for identification of one perception thresholds.
% After every stimulation event, the script presents a Likert scale asking the
% participant/experimenter to rate the sensation. If a 1 is reported, amplitude
% of stimulation is increased. After a percept is reported, one 0.1mA-up/0.3mA-down
% staircase is initiated. After 8 reversals, average amplitude is taken as threshold.
%
% When running the script, don't press the keys too quickly (count 1 second
% after each stimulation), otherwise the response window may get lost. If
% this happens, hover over the matlab icon to select the correct window
% (the one with the numbers). 
% Press 'Run' to start script. 

clear all;
close all;


%%%%%%%%% debug_mode VARIABLE %%%%%%%%%%
debug_mode = 1; % If set to 1, no actual stimulation occurs. Set this to 0 to stimulate. 

% add custom rounding function to avoid version issues
roundn = @(x,n) round(x .* 10.^n)./10.^n;   % Round ‘x’ To ‘n’ Digits, Emulates Latest ‘round’ Function


% remind user to start in voltage mode
prompt = 'For safety, switch to Voltage mode and remove electrode leads from stimulator whenever stimulation is not being applied. ';
x = input(prompt);

% Prompt for input of filename (subject name), condition list, and other parameters
prompt = {'Enter Participant ID:', 'Enter Pulse Width', 'Enter Frequency','Enter Staircase Type'};
dlg_title = 'Input';
num_lines = 1;
defaultans = {'ECXXX', '200', '25','Percept'};
userData = inputdlg(prompt,dlg_title,num_lines,defaultans);

% convert to usable format
subjName=cell2mat(userData(1));
params.pw=str2double(userData(2)); % set pulse width (e.g., 300)
params.freq=str2double(userData(3)); % set frequency (e.g., 25)
params.staircasetype = userData{4};

%%%%%%%%% SET UP DAQ DEVICE %%%%%%%%%%

% Get the name assigned to the DAQ device. The first time this script is run on a new
% computer, you should look at 'd' and assign this name to the second argument
% of addAnalogOutputChannel
if debug_mode ==0
    d = daq.getDevices;
    Stim = daq.createSession('ni');
    addAnalogOutputChannel(Stim,'Dev1',1,'Voltage');% adds a channel
    % with the handle Stim to the DAQs AO1 port.
    
    % send control signal to set voltage to 0, prior to switching to Current Mode
    outputSingleScan(Stim, 0);
end
% prompt for switching to Current Mode
prompt = 'You may now plug in the electrodes and switch to Current Mode. Press Enter to begin staircase.';
x = input(prompt);

% set up background and response figures

% initialize response window
ps = [0 0 1 1];
set(0, 'DefaultFigurePosition', ps);

backDrop = figure('units','normalized','outerposition',ps);
set(gcf,'Color', 'black');
set(gca,'Color','black');
set(gca,'XColor','black');
set(gca,'YColor','black');

% This code to display the text is kind of janky, feel free to edit.
likertText = {'1                                    2', 'Did not feel anything                        Felt something'};
% response
respFig = figure('units','normalized','outerposition',ps);
set(gcf,'Color', 'black');
uicontrol('Style', 'text',...
       'String', likertText,... %replace something with the text you want
       'Units','normalized',...
       'FontSize',20,...
       'BackgroundColor', 'k',...
       'ForegroundColor', 'w',...
       'Position', [0 0 1 0.5]);
set(gca,'Color','black');
set(gca,'XColor','black');
set(gca,'YColor','black');


% Global parameters
params.duration_baseline = 1; %1 seconds between trains
params.sr = 24414; % sampling frequency
params.npulses = 15; % number of pulses in pulse train
params.duration_test = params.npulses/params.freq; % duration of pulse train (s)

% set session rate on DAQ
if debug_mode == 0
    Stim.Rate = params.sr;
end

% initiate trial
t = 1;

% initialize variables
percept_revs = 0; % dat column 3
dat = []; % dat matrix
subjInput = 1; % indicates no percept
cur_stair = 0; % a stair begins after first reversal
upStep = 0.2;  % initially, step size is set at 0.2 to speed up first reversal
downStep = 0.3; % amount to reduce amplitude by after a reversal
revCap = 8; % number of reversals needed before ending script
params.amp = -0.1; % when we initiate, we want amp to be 0.1

% while subject keeps reporting that they did not feel anything
while subjInput == 1 && params.amp<3 
  % increase amplitude
  params.amp = params.amp + upStep; % for the first trial, this makes the amp 0.1

  % Setup stimulation
  buf = MakeStimBuffer(params);
  if debug_mode == 0
      % load waveform to buffer
      queueOutputData(Stim, buf');
      % initiate stimulation
      Stim.startForeground         % stim on
  end
  pause(1); % wait 1 seconds after end of stimulation to move on.

  % wait for participant response
  subjInput = getResponse(backDrop, respFig);

  % append trial info and response to trial dat
  dat(t,1) = t;
  dat(t,2) = params.amp;
  dat(t,3) = params.pw;
  dat(t,4) = cur_stair;
  dat(t,5) = subjInput;

  % add to trial number
  t = t+1;

end

params.amp = params.amp - downStep; % after first reversal, subtract downStep


%% After first reversal, initiate staircases
upStep = 0.1;  % switch to 0.1up/0.3down
downStep = 0.3;

% set amplitude of each threshold to current amplitude
percept_amp = params.amp;
cur_stair = 1;

while percept_revs < revCap && params.amp > 0 && params.amp < 3

  params.amp = percept_amp;

  % Setup stimulation
  buf = MakeStimBuffer(params);
  if debug_mode == 0
      queueOutputData(Stim, buf');    
      % initiate stimulation
      Stim.startForeground         % stim on
  end
  pause(1); % wait 1 seconds after end of stimulation to send off code

  % wait for participant response
  subjInput = getResponse(backDrop, respFig);

  % Decrease if likert scale response is above threshold limit.
  % Otherwise increase.
  if subjInput > 1
    percept_amp = percept_amp - downStep;
    percept_revs = percept_revs + 1;
  else
    percept_amp = percept_amp + upStep;
  end


  if percept_amp >= 3.0
    percept_revs = 100;
  end


  % append trial dat, move on to next trial
  dat(t,1) = t;
  dat(t,2) = params.amp;
  dat(t,3) = params.pw;
  dat(t,4) = cur_stair;
  dat(t,5) = subjInput;

  % increase trial counter
  t = t+1;
end

% close windows
close all

% append raw data to output file
data.dat = dat;

if percept_amp < 3.0
  % calculate averages from trials following first reversal
  data.percept_thres = abs(roundn(mean(dat(dat(:,4)==1,2)),2))
else
  disp('threshold greater than 3mA');
  data.percept_thres = abs(roundn(mean(dat(dat(:,4)==1,2)),2))
  %data.percept_thres = 3.0
end

% if desired, plot staircase
reset(0)
plot(data.dat(:,1),data.dat(:,2),'o-');
hold on
plot([min(data.dat(:,1)) max(data.dat(:,1))],[data.percept_thres data.percept_thres],'-')

% save thresholds and raw data as a .mat file
%save(['thresholds\' sprintf('%s_tVNS_single_Percept_Threshold',subjName)],'data');
save(['thresholds' filesep sprintf('%s_%s_threshold',subjName,params.staircasetype)],'data')

% prompt for switching to Voltage Mode
prompt = 'Switch to Voltage mode, then press Enter.';
x = input(prompt);

if debug_mode == 0
    Stim.stop();
    Stim.release();
end
