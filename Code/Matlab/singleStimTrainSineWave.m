function singleStimTrainSineWave(amp, freq, nburst)
    %singleStimTrainSineWave.m Takes a single stim waveform and presents it once.
    %
    % Inputs: 
    %   amp: amplitude (in milliamps)
    %   freq: how fast the pulses are delivered. For a sine-wave,
    %   'pulse-width' is a function of frequency
    %   npulse: number of periods in the pulse train (determines
    % Outputs:
    %   none

% remind user to start in voltage mode
prompt = 'Switch to Current mode and press enter to stimulate.';
x = input(prompt);

% get digitial to analog converter devices
d = daq.getDevices;
Stim = daq.createSession('ni');
addAnalogOutputChannel(Stim,'Dev1',1,'Voltage');% adds a channel
% with the handle Stim to the DAQs AO1 port.

% send control signal to set voltage to 0, prior to switching to Current Mode
outputSingleScan(Stim, 0);

params.sr = 40000; % sampling frequency
%% set local parameters
params.freq = freq; % frequency of stim (Hz)
params.nburst = nburst;
params.amp = amp; % input in Vols
params.duration_test = nburst/params.freq; % duration of pulse train (s)

% set session rate on DAQ
Stim.Rate = params.sr;

% Setup stimulation
buf = MakeStimBuffer_sinewave(params);

queueOutputData(Stim, buf');

% initiate stimulation
Stim.startForeground         % stim on
pause(1); % wait 1 seconds after end of stimulation to move on.

Stim.stop();
Stim.release();

prompt = 'Switch to Voltage mode if finished.';
x = input(prompt);

end
