%%%%%%%%% SET UP DAQ DEVICE %%%%%%%%%%
clear all;
close all;

% add custom rounding function to avoid version issues
roundn = @(x,n) round(x .* 10.^n)./10.^n;   % Round ‘x’ To ‘n’ Digits, Emulates Latest ‘round’ Function

% Get the name assigned to the DAQ device. The first time this script is run on a new
% computer, you should look at 'd' and assign this name to the second argument
% of addAnalogOutputChannel
d = daq.getDevices;

Stim = daq.createSession('ni');
addAnalogOutputChannel(Stim,'Dev1',1,'Voltage');% adds a channel
% with the handle Stim to the DAQs AO1 port.

% send control signal to set voltage to 0, prior to switching to Current Mode
outputSingleScan(Stim, 0);

%%

outputSingl
%% stimulated for 50ms at a specificed voltage

amp = 2; % 0.01 = 2v

outputSingleScan(Stim, 0);
outputSingleScan(Stim, amp);
pause(0.1)
outputSingleScan(Stim, 0);
disp(amp*20)
