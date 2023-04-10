function multiStimTrain_triggered(amp, pw, freq, npulse)
    %singleStimTrain.m Takes a single stim waveform and presents it once.
    %
    % Inputs: 
    %   amp: amplitude (in milliamps)
    %   pw: duration of single pulse (microseconds, see biphasic waveform.m)
    %   freq: how fast the pulses are delivered
    %   npulse: number of pulses in pulse train (with frequency, determines
    %       stimulation duration)
    % Outputs:
    %   none

% remind user to start in voltage mode
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

t = 1;
while t == 1

    queueOutputData(Stim, buf');

    % initiate stimulation
    t = input('Press ''1+enter'' to stimulate, ''2+enter'' to end experiment\n');

    Stim.startForeground         % stim on
    pause(1); % wait 1 seconds after end of stimulation to move on.

    Stim.stop();
    Stim.release();
end

prompt = 'Switch to Voltage mode if finished.';
x = input(prompt);

end
