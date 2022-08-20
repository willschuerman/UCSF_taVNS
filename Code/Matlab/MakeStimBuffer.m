function buf = MakeStimBuffer(params)
    %MakeStimBuffer.m Creates the biphasic stimulation buffer.  
    %
    % Inputs: 
    %   params: structure containing arguments to create the buffer. 
    % Outputs:
    %   buf: the stimulation waveform for a specified sampling rate. 
%% Hard coded limits on stimulation parameters
% if params.pw > 500
%     params.pw = 500;
% end

% if params.amp > 3
%     params.amp = 3;
% end

if params.amp <= 0
    params.amp = 0.1;
end

%if params.freq > 100
%    params.freq = 100;
%end

%% Add 2*pulse width (in microseconds) to the duration
% otherwise one pulse is cut off.
params.duration_test = params.duration_test + 2*(params.pw/1e6);

%% generate the biphasic waveform
if isfield(params,'ipd')
    ipd = params.ipd;
else
    ipd = 50;
end
wf = biphasic_waveform(params.amp,params.pw,ipd,params.sr);

%% generate the train for the test block
ptTest = constant_rate_pulser(params.freq, params.duration_test,params.sr);
yTest = convolve(ptTest, wf);

%% add a column of zeros to onset
% can change this number if needed (e.g., sampling rate changes)
padding = zeros(1,10);

%% generate the buffer
buf = [padding yTest];%


% test plot the buffer
% for i=1:size(buf,1)
%     plot(buf(i,:)+i*params.amp*1.5); hold on
% end
%
% % test plot the buffer
% for i=1:size(buf,1)
%     plot(buf(i,:)+i*800*1.5); hold on
% end


