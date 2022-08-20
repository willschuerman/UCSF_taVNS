function buf = MakeStimBuffer_sinewave(params)
    %MakeStimBuffer_sinewave.m Creates the sinewave stimulation buffer.  
    %
    % Inputs: 
    %   params: structure containing arguments to create the buffer. 
    % Outputs:
    %   buf: the stimulation waveform for a specified sampling rate. 

%% Hard coded limits on stimulation parameters
if params.amp > 3
    params.amp = 3;
end

if params.amp <= 0
    params.amp = 0.1;
end

% if params.freq > 100
%     params.freq = 100;
% end


%% Create sine wave burst
Fs = params.sr;
dt = 1/Fs;
StopTime = params.duration_test;
t = (0:dt:StopTime-dt)';

% sine wave
Fc = params.freq; %Hz
x = cos(2*pi*Fc*t);
amp = params.amp;
yTest = x*amp;

%% add a column of zeros to onset
% can change this number if needed (e.g., sampling rate changes)
padding = zeros(10,1);

%% generate the buffer
buf = [padding; yTest; padding];%


% test plot the buffer
% for i=1:size(buf,1)
%     plot(buf(i,:)+i*params.amp*1.5); hold on
% end
%
% % test plot the buffer
% for i=1:size(buf,1)
%     plot(buf(i,:)+i*800*1.5); hold on
% end


