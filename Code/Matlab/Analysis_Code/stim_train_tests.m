%% Stimulation train tests

% 1. FFT of pulse trains using difference pulse widths and frequencies
% 2. Model, if we lower pulse width, how much do we need to increase the
% frequency in order to produce the same current density/time?

set(0,'defaultfigurecolor',[1 1 1])

% set current working directory to folder in which this script is located,
% and add necessary files
addpath(genpath(replace(pwd(),'Analysis_Code','Stimulation_Code')));
%% 1.1 FFT of pulse trains using difference pulse widths
clf
ipds = [0,50,200,500];
pulse_widths = [200,100,50,30,20];
for ip = 1:length(ipds)
    params.ipd=ipds(ip); % distance between pulses
    subplot(2,2,ip)

    for p = 1:length(pulse_widths)
        % set parameters
        params.sr = 100000; % sampling frequency
        params.pw = pulse_widths(p); % pulse width (us)
        params.freq = 30; % frequency of stim (Hz)
        %params.npulses = 15000; % number of pulses (very long, for stability)
        params.duration_test = 4; % duration of pulse train (s)
        params.amp = 1; % input in Volts
        buf = MakeStimBuffer(params);
        [Pxx, F] = onesidedFFT(buf,params.sr);
        if params.freq > 200
            Pxx = (Pxx(F<2000));F = F(F<2000);
        else
            Pxx = (Pxx(F<200));F = F(F<200);
        end
        tot_pow = sum(Pxx);
        tot_power(p,ip) = tot_pow;
        plot(F,Pxx,'linewidth',2)
        hold on
        xlabel('Frequency (Hz)')
        ylabel('Power')
        set(gca,'FontName','Arial','FontSize',14)
    end
    title(sprintf('IPD = %d',ipds(ip)));
end
legend(split(num2str(pulse_widths)))
linkaxes
%% 
clf
imagesc(tot_power')
colormap('parula')
set(gca,'XTick',[1,2,3,4,5],'XTickLabel',split(num2str(pulse_widths)))
set(gca,'YTick',[1,2,3,4],'YTickLabel',split(num2str(ipds)))
xlabel('Pulse Width')
ylabel('Inter-Pulse-Distance')
set(gca,'FontName','Arial','FontSize',14)

colorbar
%% 1.1b FFT of pulse trains using difference pulse widths
clf
ipds = [0,20,40,60];
pulse_widths = [50,40,30,20,10];
for ip = 1:length(ipds)
    params.ipd=ipds(ip); % distance between pulses
    subplot(2,2,ip)

    for p = 1:length(pulse_widths)
        % set parameters
        params.sr = 100000; % sampling frequency
        params.pw = pulse_widths(p); % pulse width (us)
        params.freq = 30; % frequency of stim (Hz)
        %params.npulses = 15000; % number of pulses (very long, for stability)
        params.duration_test = 4; % duration of pulse train (s)
        params.amp = 1; % input in Volts
        buf = MakeStimBuffer(params);
        [Pxx, F] = onesidedFFT(buf,params.sr);
        if params.freq > 200
            Pxx = (Pxx(F<2000));F = F(F<2000);
        else
            Pxx = (Pxx(F<200));F = F(F<200);
        end
        tot_pow = sum(Pxx);
        tot_power(p,ip) = tot_pow;
        plot(F,Pxx,'linewidth',2)
        hold on
        xlabel('Frequency (Hz)')
        ylabel('Power')
        set(gca,'FontName','Arial','FontSize',14)
    end
    title(sprintf('IPD = %d',ipds(ip)));
end
legend(split(num2str(pulse_widths)))
linkaxes
%% 
clf
imagesc(tot_power')
colormap('parula')
set(gca,'XTick',[1,2,3,4,5],'XTickLabel',split(num2str(pulse_widths)))
set(gca,'YTick',[1,2,3,4],'YTickLabel',split(num2str(ipds)))
xlabel('Pulse Width')
ylabel('Inter-Pulse-Distance')
set(gca,'FontName','Arial','FontSize',14)

colorbar
%% 1.2 FFT of pulse trains using difference pulse widths
clf
pulse_widths = [200,100,50,30,20];
frequencies = [30,50,90,1000];

tot_power = zeros(length(pulse_widths),length(frequencies));

for f1 = 1:length(frequencies)
    params.freq=frequencies(f1); % distance between pulses
    subplot(2,2,f1)

    for p = 1:length(pulse_widths)
        % set parameters
        params.sr = 100000; % sampling frequency
        params.pw = pulse_widths(p); % pulse width (us)
        %params.freq = 30; % frequency of stim (Hz)
        %params.npulses = 15000; % number of pulses (very long, for stability)
        params.duration_test = 4; % duration of pulse train (s)
        params.amp = 1; % input in Volts
        params.ipd = 50;
        buf = MakeStimBuffer(params);
        [Pxx, F] = onesidedFFT(buf,params.sr);
        if params.freq > 200
            Pxx = (Pxx(F<2000));F = F(F<2000);
        else
            Pxx = (Pxx(F<2000));F = F(F<2000);
        end
        tot_pow = sum(Pxx);
        tot_power(p,f1) = tot_pow;
        %Pxx = Pxx - nanmedian(Pxx);
        plot(F,Pxx,'linewidth',2)
        hold on
        xlabel('Frequency (Hz)')
        set(gca,'FontName','Arial','FontSize',14)
    end
    title(sprintf('Frequency = %d',frequencies(f1)));
end
legend(split(num2str(pulse_widths)))

%% 
clf
imagesc(tot_power')
colormap('parula')
set(gca,'XTick',[1,2,3,4,5],'XTickLabel',split(num2str(pulse_widths)))
set(gca,'YTick',[1,2,3,4],'YTickLabel',split(num2str(frequencies)))
xlabel('Pulse Width')
ylabel('Frequency')
set(gca,'FontName','Arial','FontSize',14)

colorbar
%% 2. Create an equivalence metric for total current density delivered

amps = 0.1:0.1:2;
pulse_widths = (10:10:100);
frequencies = [25,50,75,100,500,1000];
tot_power = zeros(length(amps),length(pulse_widths),length(frequencies));

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
            tot_pow = sum(abs(buf));
            tot_power(a,p,f) = tot_pow;
        end
    end
end
%%

imagesc(squeeze(tot_power(1,:,:))');
colormap('parula')
set(gca,'XTick',(1:length(pulse_widths)),'XTickLabel',split(num2str(pulse_widths)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Pulse Width')
ylabel('Frequency')
set(gca,'FontName','Arial','FontSize',14)
%%

imagesc(squeeze(tot_power(:,1,:))');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Amp')
ylabel('Frequency')
set(gca,'FontName','Arial','FontSize',14)
%%
clf
imagesc(squeeze(tot_power(:,:,1))');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(pulse_widths)),'YTickLabel',split(num2str(pulse_widths)))
xlabel('Amp')
ylabel('Pulse Width')
set(gca,'FontName','Arial','FontSize',14)

%%
for f = 1:length(frequencies)
    subplot(3,2,f)

    imagesc(squeeze(tot_power(:,:,f))');
    colormap('parula')
    set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
    set(gca,'YTick',(1:length(pulse_widths)),'YTickLabel',split(num2str(pulse_widths)))
    xlabel('Amp')
    ylabel('Pulse Width')
    set(gca,'FontName','Arial','FontSize',14)
    title(sprintf('%dHz',frequencies(f)))
    colorbar
end


%%
params.sr = 100000; % sampling frequency
params.pw = 200; % pulse width (us)
params.freq = 30; % frequency of stim (Hz)
params.amp = 1;
params.npulses = 15; % number of pulses
params.ipd=50;
params.duration_test = params.npulses/params.freq; % duration of pulse train (s)
%params.amp = 1; % input in Volts
reference_buf = MakeStimBuffer(params);
sum(abs(reference_buf))

[Pxx, F] = onesidedFFT(reference_buf,params.sr);
Pxx = (Pxx(F<2000));F = F(F<2000);
sum(Pxx)

%%


amps = 0.1:0.1:3;
frequencies = 100:100:5000;
tot_power = zeros(length(amps),length(frequencies));

for f = 1:length(frequencies)
    params.freq=frequencies(f); % distance between pulses

    for a = 1:length(amps)
        params.amp=amps(a); % distance between pulses
    
        % set parameters
        params.sr = 100000; % sampling frequency
        params.pw = 50; % pulse width (us)
        params.ipd = 50;
        %params.freq = 30; % frequency of stim (Hz)
        params.npulses = 15; % number of pulses
        params.duration_test = params.npulses/params.freq; % duration of pulse train (s)
        %params.amp = 1; % input in Volts
        buf = MakeStimBuffer(params);
        tot_pow = sum(abs(buf));
        tot_power(a,f) = tot_pow;
    end
end

%%
clf
imagesc(tot_power');
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(frequencies)),'YTickLabel',split(num2str(frequencies)))
xlabel('Amp')
ylabel('Frequency')
set(gca,'FontName','Arial','FontSize',14)
colorbar

%%
amps = 0.1:0.5:3;
npulses = 100:1000:5000;
tot_current = zeros(length(amps),length(npulses));
tot_power = zeros(length(amps),length(npulses));

for f = 1:length(npulses)
    params.npulses=npulses(f); % distance between pulses

    for a = 1:length(amps)
        params.amp=amps(a); % distance between pulses
    
        % set parameters
        params.sr = 100000; % sampling frequency
        params.pw = 50; % pulse width (us)
        params.ipd = 50;
        params.freq = 30; % frequency of stim (Hz)
        %params.npulses = 15; % number of pulses
        params.duration_test = params.npulses/params.freq; % duration of pulse train (s)
        %params.amp = 1; % input in Volts
        buf = MakeStimBuffer(params);
        tot_current(a,f) = sum(abs(buf));

        [Pxx, F] = onesidedFFT(buf,params.sr);
        Pxx = (Pxx(F<2000));F = F(F<2000);
        tot_pow = sum(Pxx);
        tot_power(a,f) = tot_pow;
    end
end

%%
clf
%imagesc(tot_power>0.0252);
imagesc(tot_power')
colormap('parula')
set(gca,'XTick',(1:length(amps)),'XTickLabel',split(num2str(amps)))
set(gca,'YTick',(1:length(npulses)),'YTickLabel',split(num2str(npulses)))
xlabel('Amp')
ylabel('Npulses')
set(gca,'FontName','Arial','FontSize',14)
colorbar
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