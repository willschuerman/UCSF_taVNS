
d = daq.getDevices;

Stim = daq.createSession('ni');
addAnalogOutputChannel(Stim,'Dev1',1,'Voltage');% adds a channel
% with the handle Stim to the DAQs AO1 port.

% send control signal to set voltage to 0, prior to switching to Current Mode
outputSingleScan(Stim, 0);

Fs = 44000;
dt = 1/Fs;
StopTime = 2;
t = (0:dt:StopTime-dt)';

Stim.Rate = Fs;


% sine wave
Fc = 25; %Hz
x = cos(2*pi*Fc*t);
amp = 0.3;
x = x*amp;

% plot(t,x)

queueOutputData(Stim, x);

% initiate stimulation
disp('starting stim')
Stim.startForeground         % stim on
pause(1); % wait 1 seconds after end of stimulation to move on.
disp('stim over')

outputSingleScan(Stim,0);

Stim.stop();
Stim.release();