function buf = plotSampleWaveform(amp, pw, freq, npulse,varargin)
    %plotSampleWaveform.m Takes a single stim waveform and plots it. 
    %
    % Inputs: 
    %   amp: amplitude (in milliamps)
    %   pw: duration of single pulse (microseconds, see biphasic waveform.m)
    %   freq: how fast the pulses are delivered
    %   npulse: number of pulses in pulse train (with frequency, determines
    %       stimulation duration)
    %   varargin: if set to 'sine', plots a sinewave buffer. Defaults to
    %   'square'
    % Outputs:
    %   none

if ~isempty(varargin)
    waveform = varargin{1};
else
    waveform = 'square';
end

params.sr = 44100; % sampling frequency

%% set local parameters
params.pw = pw; % pulse width (us)
params.freq = freq; % frequency of stim (Hz)
params.npulses = npulse;
params.duration_test = npulse/params.freq; % duration of pulse train (s)
params.amp = amp; % input in Vols
params.ipd = 50; % hardcoded at 50 microseconds

if strcmp(waveform,'sine')
    buf = MakeStimBuffer_sinewave(params);
else
    buf = MakeStimBuffer(params);
end


figure;
plot((1:length(buf))/params.sr, buf, 'r');
hold on
xlabel('Time (s)');
ylabel('Voltage');
ylim([-1.5 1.5]);
xlim([-1 2]);
plot(get(gca,'xlim'),[0 0],'b');

grid on


end