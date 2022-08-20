% multiRandomStaircase
%%% script for simultaneous identification of two perception thresholds.
% After every stimulation event, the script presents a Likert scale asking the
% participant/experimenter to rate the sensation. If a 1 is reported, amplitude
% of stimulation is increased. After a percept is reported, two 0.1mA-up/0.3mA-down
% staircases are initiated. After 8 reversals, average amplitude is taken as threshold.
%
%%%%%%%%% SET UP DAQ DEVICE %%%%%%%%%%
clear all;
close all;

% add custom rounding function to avoid version issues
roundn = @(x,n) round(x .* 10.^n)./10.^n;   % Round ‘x’ To ‘n’ Digits, Emulates Latest ‘round’ Function

% remind user to start in voltage mode
prompt = 'For safety, switch to Voltage mode and remove electrode leads from stimulator whenever stimulation is not being applied. ';
x = input(prompt);

% Prompt for input of filename (subject name), condition list, and other parameters
prompt = {'Enter Participant ID:'};
dlg_title = 'Input';
num_lines = 1;
defaultans = {'ECXXX'};
userData = inputdlg(prompt,dlg_title,num_lines,defaultans);

% convert to usable format
subjName=cell2mat(userData(1));

% Get the name assigned to the DAQ device. The first time this script is run on a new
% computer, you should look at 'd' and assign this name to the second argument
% of addAnalogOutputChannel
d = daq.getDevices;

Stim = daq.createSession('ni');
addAnalogOutputChannel(Stim,'DAQ_ID',1,'Voltage');% adds a channel
% with the handle Stim to the DAQs AO1 port.

% send control signal to set voltage to 0, prior to switching to Current Mode
outputSingleScan(Stim, 0);

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
likertText = {'1                            2                            3                            4                         5', 'Did not feel anything                        uncomfortable                                     painful'};
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
params.sr = 24000; % sampling frequency
params.freq1 = 25; % frequency constant at 25Hz, does not seem to affect perceptual threshold
params.npulses = 15; % number of pulses in pulse train
params.duration_test = params.npulses/params.freq1; % duration of pulse train (s)

% set session rate on DAQ
Stim.Rate = params.sr;

% initiate trial
t = 1;

% initialize variables
percept_300_revs = 0; % dat column 3
percept_500_revs = 0; % dat column 4
dat = []; % dat matrix
subjInput = 1; % indicates no percept
cur_stair = 0; % a stair begins after first reversal
upStep = 0.2;  % initially, step size is set at 0.2 to speed up first reversal
downStep = 0.3; % amount to reduce amplitude by after a reversal
revCap = 8; % number of reversals needed before ending script
params.amp = -0.1; % when we initiate, we want amp to be 0.1

% while subject keeps reporting that they did not feel anything
while subjInput == 1
  % increase amplitude
  params.amp = params.amp + upStep; % for the first trial, this makes the amp 0.1

  % Setup stimulation
  buf = MakeStimBuffer(params);
  queueOutputData(Stim, buf');

  % initiate stimulation
  Stim.startForeground         % stim on
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
stairs = [1 2];
upStep = 0.1;  % switch to 0.1up/0.3down
downStep = 0.3;

% set amplitude of each threshold to current amplitude
percept_300_amp = params.amp;
percept_500_amp = params.amp;
first_rev_300 = false; % note that 300 pulse width has not had its first reversal

% while revCap has not been reached for both staircases
while ~isempty(stairs)

    % randomly sample from staircases, and remove if reversals exceed 8.
    if length(stairs) < 2
        cur_stair = stairs;
    else
        cur_stair = randi(2,1);
    end

    % 300 pulse width staircase
    if cur_stair == 1
        % set trial amplitude to staircase amplitude
        params.amp = percept_300_amp;
        params.pw = 300;

        % Setup stimulation
        buf = MakeStimBuffer(params);
        queueOutputData(Stim, buf');

        % initiate stimulation
        Stim.startForeground         % stim on
        pause(1);                    % wait 1 seconds after end of stimulation

        % wait for participant response
        subjInput = getResponse(backDrop, respFig);

        % Decrease if likert scale response is above one (threshold).
        % Otherwise increase.
        if subjInput > 1
          percept_300_amp = percept_300_amp - downStep;
          percept_300_revs = percept_300_revs + 1;
          if first_rev_300 == false
            first_rev_300 = true;
          end
        else
          percept_300_amp = percept_300_amp + upStep;
        end

        % remove from array if reversal cap  has been reached or amplitude is equal to or greater than 3
        if percept_300_revs >= revCap || percept_300_amp >= 3.0
          stairs(stairs == cur_stair) = [];
          first_rev_300 = true; % need this, otherwise there is never a data point
        end

        % for this staircase, if the first reversal hasn't happened, continue to call the staircase "0"
        if first_rev_300 == false
          cur_stair = 0;
        end
    % 500 pulse width staircase
    elseif cur_stair == 2
      params.amp = percept_500_amp;
      params.pw = 500;

      % Setup stimulation
      buf = MakeStimBuffer(params);
      queueOutputData(Stim, buf');

      % initiate stimulation
      Stim.startForeground         % stim on
      pause(1); % wait 1 seconds after end of stimulation to send off code

      % wait for participant response
      subjInput = getResponse(backDrop, respFig);

      % Decrease if likert scale response is above threshold limit.
      % Otherwise increase.
      if subjInput > 1
          percept_500_amp = percept_500_amp - downStep;
          percept_500_revs = percept_500_revs + 1;
      else
          percept_500_amp = percept_500_amp + upStep;
      end

       % remove from array if reversal cap  has been reached
      if percept_500_revs >= revCap
        stairs(stairs == cur_stair) = [];
      end
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

if percept_300_amp < 3.0
  % calculate averages from trials following first reversal
  data.percept_300_thres = roundn(mean(dat(dat(:,4)==1),2),1)
  data.percept_500_thres = roundn(mean(dat(dat(:,4)==2),2),1)
else
  disp('300 pulse width greater than 3mA');
  data.percept_300_thres = 3.0
  data.percept_500_thres = roundn(mean(dat(dat(:,4)==2),2),1)
end

% if desired, plot staircases
%plot(data.dat(data.dat(:,4)==1,2));
%hold on
%plot(data.dat(data.dat(:,4)==2,2));

% save thresholds and raw data as a .mat file
save(sprintf('%s_tVNS_Percept_Thresholds',subjName),'data');


% prompt for switching to Voltage Mode
prompt = 'Switch to Voltage mode, then press Enter.';
x = input(prompt);

Stim.stop();
Stim.release();



