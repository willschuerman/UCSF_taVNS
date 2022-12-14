%% Stimulation train tests

% 1. Total sum of current delivered and total FFT power for a signal
% consisting of a fixed number of pulses. 
% 2. Total sum of current delivered and total FFT power for a signal
% consisting of a fixed duration. 
% 3. Model of tradeoff between frequency (number of pulses) and amplitude
% for equivalent current density (current delivered or FFT)

set(0,'defaultfigurecolor',[1 1 1])

% set current working directory to folder in which this script is located,
% and add necessary files
addpath(genpath(replace(pwd(),'Analysis_Code','Stimulation_Code')));

%% 1. Generate estimates for signal with fixed number of pulses 

amps = 0.1:0.1:1;
pulse_widths = (10:10:100);
frequencies = 25:25:250;
total_current = zeros(length(amps),length(pulse_widths),length(frequencies));
total_power = zeros(length(amps),length(pulse_widths),length(frequencies));

params.ipd = 0;
for f = 1:length(frequencies)
    params.freq=frequencies(f); % distance between pulses

    for a = 1:length(amps)
        params.amp=amps(a); % distance between pulses
    
        for p = 1:length(pulse_widths)
            % set parameters
            params.sr = 100000; % sampling frequency
            params.pw = pulse_widths(p); % pulse width (us)
            %params.freq = 30; % frequency of stim (Hz)
            params.npulses = 15; % number of pulses
            params.duration_test = params.npulses/params.freq; % duration of pulse train (s)
            %params.amp = 1; % input in Volts
            buf = MakeStimBuffer(params);
            total_current(a,p,f) = sum(abs(buf));

            [Pxx, F] = onesidedFFT(buf,params.sr);
            Pxx = (Pxx(F<250));F = F(F<250);
            total_power(a,p,f) = sum(Pxx);
        end
    end
end
%% 1.1a Amplitude Fixed - Current
subplot(2,3,1)
imagesc(squeeze(total_current(10,:,:))');
colormap('parula')
set(gca,'XTick',(1:length(pulse_widths)),'XTickLabel',split(num2str(pulse_widths)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Pulse Width')
ylabel('Frequency')
set(gca,'CLim',[min(total_current(:)), max(total_current(:))])
colorbar()
set(gca,'FontName','Arial','FontSize',14)
title('Amplitude = 1mA')

% 1.1b Pulse Width Fixed - Current
subplot(2,3,2)
imagesc(squeeze(total_current(:,10,:))');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Amp')
ylabel('Frequency')
set(gca,'CLim',[min(total_current(:)), max(total_current(:))])
set(gca,'FontName','Arial','FontSize',14)
colorbar()
title('Pulse Width = 100')

% 1.1c Frequency Fixed - Current
subplot(2,3,3)
imagesc(squeeze(total_current(:,:,10))');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(pulse_widths)),'YTickLabel',split(num2str(pulse_widths)))
xlabel('Amp')
ylabel('Pulse Width')
set(gca,'FontName','Arial','FontSize',14)
set(gca,'CLim',[min(total_current(:)), max(total_current(:))])
colorbar()
title('Frequency = 250Hz')

% 1.1d Amplitude Fixed - FFT
subplot(2,3,4)
imagesc(squeeze(total_power(10,:,:))');
colormap('parula')
set(gca,'XTick',(1:length(pulse_widths)),'XTickLabel',split(num2str(pulse_widths)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Pulse Width')
ylabel('Frequency')
set(gca,'CLim',[min(total_power(:)), max(total_power(:))])
colorbar()
set(gca,'FontName','Arial','FontSize',14)

% 1.1e Pulse Width Fixed - FFT
subplot(2,3,5)
imagesc(squeeze(total_power(:,10,:))');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Amp')
ylabel('Frequency')
set(gca,'FontName','Arial','FontSize',14)
colorbar()

% 1.1f Frequency Fixed - FFT
subplot(2,3,6)
imagesc(squeeze(total_power(:,:,10))');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(pulse_widths)),'YTickLabel',split(num2str(pulse_widths)))
xlabel('Amp')
ylabel('Pulse Width')
set(gca,'FontName','Arial','FontSize',14)
colorbar()




%% 2. Generate estimates for signal with fixed number of pulses 

amps = 0.1:0.1:1;
pulse_widths = (10:10:100);
frequencies = 25:25:250;
total_current = zeros(length(amps),length(pulse_widths),length(frequencies));
total_power = zeros(length(amps),length(pulse_widths),length(frequencies));

params.ipd = 0;
for f = 1:length(frequencies)
    params.freq=frequencies(f); % distance between pulses

    for a = 1:length(amps)
        params.amp=amps(a); % distance between pulses
    
        for p = 1:length(pulse_widths)
            % set parameters
            params.sr = 100000; % sampling frequency
            params.pw = pulse_widths(p); % pulse width (us)
            %params.freq = 30; % frequency of stim (Hz)
            %params.npulses = 15; % number of pulses
            %params.duration_test = params.npulses/params.freq; 
            params.duration_test = 1;% duration of pulse train (s)
            %params.amp = 1; % input in Volts
            buf = MakeStimBuffer(params);
            total_current(a,p,f) = sum(abs(buf));

            [Pxx, F] = onesidedFFT(buf,params.sr);
            Pxx = (Pxx(F<250));F = F(F<250);
            total_power(a,p,f) = sum(Pxx);
        end
    end
end
%% 2.1a Amplitude Fixed - Current
subplot(2,3,1)
imagesc(squeeze(total_current(10,:,:))');
colormap('parula')
set(gca,'XTick',(1:length(pulse_widths)),'XTickLabel',split(num2str(pulse_widths)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Pulse Width')
ylabel('Frequency')
set(gca,'CLim',[min(total_current(:)), max(total_current(:))])
colorbar()
set(gca,'FontName','Arial','FontSize',14)
title('Amplitude = 1mA')

% 2.1b Pulse Width Fixed - Current
subplot(2,3,2)
imagesc(squeeze(total_current(:,10,:))');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Amp')
ylabel('Frequency')
set(gca,'CLim',[min(total_current(:)), max(total_current(:))])
set(gca,'FontName','Arial','FontSize',14)
colorbar()
title('Pulse Width = 100')

% 2.1c Frequency Fixed - Current
subplot(2,3,3)
imagesc(squeeze(total_current(:,:,10))');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(pulse_widths)),'YTickLabel',split(num2str(pulse_widths)))
xlabel('Amp')
ylabel('Pulse Width')
set(gca,'FontName','Arial','FontSize',14)
set(gca,'CLim',[min(total_current(:)), max(total_current(:))])
colorbar()
title('Frequency = 250Hz')

% 2.1d Amplitude Fixed - FFT
subplot(2,3,4)
imagesc(squeeze(total_power(10,:,:))');
colormap('parula')
set(gca,'XTick',(1:length(pulse_widths)),'XTickLabel',split(num2str(pulse_widths)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Pulse Width')
ylabel('Frequency')
set(gca,'CLim',[min(total_power(:)), max(total_power(:))])
colorbar()
set(gca,'FontName','Arial','FontSize',14)

% 2.1e Pulse Width Fixed - FFT
subplot(2,3,5)
imagesc(squeeze(total_power(:,10,:))');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Amp')
ylabel('Frequency')
set(gca,'FontName','Arial','FontSize',14)
colorbar()

% 2.1f Frequency Fixed - FFT
subplot(2,3,6)
imagesc(squeeze(total_power(:,:,10))');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(pulse_widths)),'YTickLabel',split(num2str(pulse_widths)))
xlabel('Amp')
ylabel('Pulse Width')
set(gca,'FontName','Arial','FontSize',14)
colorbar()


%% 3. Model of equivalence, based on reference signal. 

% 3.1 Create reference signal (30-pulses)

params.sr = 100000; % sampling frequency
params.pw = 200; % pulse width (us)
params.freq = 30; % frequency of stim (Hz)
params.amp = 1;
params.npulses = 30; % number of pulses
params.ipd=50;
params.duration_test = params.npulses/params.freq; % duration of pulse train (s)
%params.amp = 1; % input in Volts
reference_buf = MakeStimBuffer(params);
reference_buf(fix(length(reference_buf)/2)-20:end) = 0;

reference_current = sum(abs(reference_buf));

[Pxx, F] = onesidedFFT(reference_buf,params.sr);
Pxx = (Pxx(F<250));F = F(F<250);
reference_power = sum(Pxx);


%% 3.1a Amplitude Fixed - Current
subplot(2,3,1)
tmp = (squeeze(total_current(10,:,:))');
imagesc(tmp>=reference_current)
colormap('parula')
set(gca,'XTick',(1:length(pulse_widths)),'XTickLabel',split(num2str(pulse_widths)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Pulse Width')
ylabel('Frequency')
colorbar()
set(gca,'FontName','Arial','FontSize',14)
title('Amplitude = 1mA')

% 3.1b Pulse Width Fixed - Current
subplot(2,3,2)
tmp = (squeeze(total_current(:,10,:))');
imagesc(tmp>=reference_current)
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Amp')
ylabel('Frequency')
colorbar()
title('Pulse Width = 100')
set(gca,'FontName','Arial','FontSize',14)

% 3.1c Frequency Fixed - Current
subplot(2,3,3)
tmp = (squeeze(total_current(:,:,10))');
imagesc(tmp>=reference_current)
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(pulse_widths)),'YTickLabel',split(num2str(pulse_widths)))
xlabel('Amp')
ylabel('Pulse Width')
set(gca,'FontName','Arial','FontSize',14)
colorbar()
title('Frequency = 250Hz')

% 3.1d Amplitude Fixed - FFT
subplot(2,3,4)
tmp = (squeeze(total_power(10,:,:))');
imagesc(tmp>=reference_power);
colormap('parula')
set(gca,'XTick',(1:length(pulse_widths)),'XTickLabel',split(num2str(pulse_widths)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Pulse Width')
ylabel('Frequency')
colorbar()
set(gca,'FontName','Arial','FontSize',14)

% 3.1e Pulse Width Fixed - FFT
subplot(2,3,5)
tmp = (squeeze(total_power(:,10,:))');
imagesc(tmp>=reference_power);
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Amp')
ylabel('Frequency')
colorbar()
set(gca,'FontName','Arial','FontSize',14)

% 3.1f Frequency Fixed - FFT
subplot(2,3,6)
tmp = (squeeze(total_power(:,:,10))');
imagesc(tmp>=reference_power);
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(pulse_widths)),'YTickLabel',split(num2str(pulse_widths)))
xlabel('Amp')
ylabel('Pulse Width')
set(gca,'FontName','Arial','FontSize',14)
colorbar()


%% 4 FFT of pulse trains using difference pulse widths
clf

pulse_widths = [30,50,100,200];
frequences = [30,60,90];
for p = 1:length(pulse_widths)
    subplot(1,4,p)
    for f = 1:length(frequencies)
        % set parameters
        params.sr = 100000; % sampling frequency
        params.pw = pulse_widths(p); % pulse width (us)
        params.freq = frequencies(f); % frequency of stim (Hz)
        %params.npulses = 15000; % number of pulses (very long, for stability)
        params.duration_test = 1; % duration of pulse train (s)
        params.amp = 1; % input in Volts
        buf = MakeStimBuffer(params);
        [Pxx, F] = onesidedFFT(buf,params.sr);
        Pxx = (Pxx(F<250));F = F(F<250);
        plot(F,Pxx,'linewidth',1)
        hold on
        xlabel('Frequency (Hz)')
        ylabel('Power')
        set(gca,'FontName','Arial','FontSize',14)
        title(sprintf('Pulse Width. = %dus',pulse_widths(p)))
    end
end
legend(split(num2str(frequencies)))

linkaxes

%% Sanity check
Fs = 1000;  
T = 1/Fs;  
L = 1500;        
t = (0:L-1)*T; 
S = 0.7*sin(2*pi*50*t) + sin(2*pi*120*t);
X = S + 2*randn(size(t));
[power_one_sided, frequency_vector] = onesidedFFT(X,Fs);
plot(frequency_vector,power_one_sided)

%% Function
function [power_one_sided, frequency_vector] = onesidedFFT(signal,sampling_rate)
    signal_length = length(signal);
    nfft = 2^nextpow2(signal_length);
    signal_fft = fft(signal,nfft);
    power_two_sided = abs(signal_fft/nfft);
    power_one_sided = power_two_sided(1:nfft/2+1);
    power_one_sided(2:end-1) = 2*power_one_sided(2:end-1);
    frequency_vector = sampling_rate*(0:(nfft/2))/nfft;
end