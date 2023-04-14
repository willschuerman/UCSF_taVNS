function taVNS_speech_prep(amp, stimFlag, pw, freq, npulse, expDur, iti)
    %singleStimTrain.m Takes a single stim waveform and presents it once.
    %
    % Inputs: 
    %   amp: amplitude (in milliamps)
    %   pw: duration of single pulse (microseconds, see biphasic waveform.m)
    %   freq: how fast the pulses are delivered
    %   npulse: number of pulses in pulse train (with frequency, determines
    %       stimulation duration)
    %   expDur: experiment duration (in seconds; 5 min=300)
    %   iti: time between stimulation events (in seconds)
    % Outputs:
    %   none

% DEFAULTS
clc;
if nargin < 1; error('PLEASE ENTER AMPLITUDE!'); end;
if nargin < 6
    if ~exist('pw','var'); pw = 100; end;
    if ~exist('freq','var'); freq = 30; end;
    if ~exist('npulse','var'); npulse = 30; end;
    if ~exist('expDur','var'); expDur = 300; end;
    if ~exist('iti','var'); iti = 7.5; end;
    if ~exist('stimFlag','var'); stimFlag = 1; end;
end

iti = iti-1.2; % offset to account for delays

% remind user to start in voltage mode
fprintf('General parameters should be amp=(depends on participant), stimFlag=(experimenter determines), pw=100, freq=30, npulse=30, expDur=300, iti=7.5\n')
prompt = 'Switch to Current mode and press enter to stimulate.';
x = input(prompt);


d = daq.getDevices;

Stim = daq.createSession('ni');
addAnalogOutputChannel(Stim,d(1).ID,1,'Voltage');% adds a channel
% with the handle Stim to the DAQs AO1 port.

% send control signal to set voltage to 0, prior to switching to Current Mode
outputSingleScan(Stim, 0);

params.sr = 100000; % sampling frequency
%% set local parameters
params.pw = pw; % pulse width (us)
params.freq = freq; % frequency of stim (Hz)
params.npulses = npulse;
params.duration_test = npulse/params.freq; % duration of pulse train (s)
params.amp = amp; % input in Vols
params.ipd=50;
% set session rate on DAQ
Stim.Rate = params.sr;
% Setup stimulation
buf = MakeStimBuffer(params);

expStart = tic;
elapsedDur = toc(expStart);

while elapsedDur < expDur
    trlDur = tic;
    elapsedDur = toc(expStart);

    queueOutputData(Stim, buf');

    % initiate stimulation

    if stimFlag
        Stim.startForeground         % stim on
        %     pause(1); % wait 1 seconds after end of stimulation to move on.

        Stim.stop();
        Stim.release();
    else
        pause(1.2); % to account for lack of stim delay
    end

    pause(iti);
    toc(trlDur)
end

prompt = 'Switch to Voltage mode if finished.';
x = input(prompt);

end
