%% Analyze Raw Data
% This script performs basic analyses on the converted .acq files from
% Acqknowledge (raw physio data). 
% Script needs to start in the folder containing
% 'analyze_raw_physio_data.m'
set(0,'defaultfigurecolor',[1 1 1])

%% Background 
% Baker & Baker, 1955:
% -epinephrine and norepinephrine increase the magnitude of the QRS complex
% (R_amplitude)
% -acetylcholine depresses the QRS-complex (R_amplitude)

%% Add Current folder then Change directory to data folder
addpath(genpath(pwd()))
cd(['..' filesep '..' filesep '..'])
cd('Data')

%% Load data

data = load(['Physiology_tests' filesep 'tVNS Danielle.mat']);

%% get rid of bad data at end of experiment
data.data = data.data(1:40210900,:);
%% plot raw data
subplot(3,1,1)
plot(data.data(:,1))
title('Stimulator Output')
subplot(3,1,2)
plot(data.data(:,2))
title('Electrocardiogram')
subplot(3,1,3)
plot(data.data(:,3))
title('PPG')

%% close windows
close all
%% get onset of stimulation periods
ANIN = data.data(:,1);
ANIN_fs = 10000; % need to find the real sampling rate
stimFreq = 30;
hpFreq = 1000;
on_threshold = 0.2;
pulse_threshold=max(ANIN)/2;
min_dur=0.3;
padtime=0;
plot_debug=1;
flip = 0;
[onsets,offsets] = findStimulationPeriods(ANIN,ANIN_fs,stimFreq,hpFreq,on_threshold,min_dur,padtime,flip);
%% display stimulation signal with onsets marked. 
plot(ANIN)
vline(onsets,'r-')
%% extract EKG around pulse periods
close all

subplot(3,1,1)
plot(data.data(onsets(1)-10000:onsets(3),1))
title('Stimulator Output')
subplot(3,1,2)
plot(data.data(onsets(1)-10000:onsets(3),2))
title('ECG')
subplot(3,1,3)
plot(data.data(onsets(1)-10000:onsets(3),3))
title('PPG')

%% get locations of ECG peaks
close all
samples = 1:length(data.data);
[peakloc,peakmag] = peakfinder(data.data(:,2));
plot(samples,data.data(:,2))
hold on
scatter(samples(peakloc),data.data(peakloc,2))

%% get onset and offset of stimulation periods
stim_period_onsets = [onsets(1) onsets(1+find(diff(onsets)>mean(diff(onsets))*10))];
plot(data.data(:,1))
title('Stimulator Output')
hold on
vline(stim_period_onsets,'r-')


%% Visualize ECG metrics
close all
% extract a single pulse
Ri = 500;
peak_data = data.data(peakloc(Ri)-10000:peakloc(Ri)+10000,2);
peak_deriv = diff(peak_data);
nsamples = length(peak_data);
samps = 1:length(peak_data);

% get Q and S position
localmins = islocalmin(peak_data(1:round(nsamples/2)),'MinProminence',0.01);
Qi = max(find(localmins));
localmins = islocalmin(peak_data(round(nsamples/2):end),'MinProminence',0.01);
Si = round(nsamples/2)+min(find(localmins));

plot(samps,peak_data)
hold on
%scatter(samps(localmins),peak_data(localmins))
%scatter(round(nsamples/2),peak_data(round(nsamples/2)))
scatter(Qi,peak_data(Qi),'filled')
scatter(Si,peak_data(Si),'filled')

%% For each heart beat, extract the following metrics
% https://ecgwaves.com/topic/ecg-normal-p-wave-qrs-complex-st-segment-t-wave-j-point/
% 1. Duration of QRS complex (note, due to ease of computation, Q and S are 
% measured as the local minimum relative to R, not the zero-crossing).  
% 2. Amplitude of R relative to Q.
% 3. R-wave peak time (peak of R relative to Q)

% We skip the first and last peak
QRS_durations = zeros(length(peakloc)-2,1);
R_amplitudes = zeros(length(peakloc)-2,1);
R_wave_peak_times = zeros(length(peakloc)-2,1);

for Ri = 2:length(peakloc)-1
    % extract a single pulse
    peak_data = data.data(peakloc(Ri)-10000:peakloc(Ri)+10000,2);
    peak_deriv = diff(peak_data);
    nsamples = length(peak_data);
    samps = 1:length(peak_data);

    % get Q and S position
    localmins = islocalmin(peak_data(1:round(nsamples/2)),'MinProminence',0.01);
    Qi = max(find(localmins));
    localmins = islocalmin(peak_data(round(nsamples/2):end),'MinProminence',0.01);
    Si = round(nsamples/2)+min(find(localmins));

    % 1. Duration of QRS complex
    qrs_dur = Si-Qi;
    QRS_durations(Ri) = qrs_dur;
    % 2. R wave amplitude
    r_amp = data.data(peakloc(Ri),2) - peak_data(Qi);
    R_amplitudes(Ri) = r_amp;
    % 3. R-wave peak time
    r_wave_peak_time = round(length(peak_data)/2) - Qi;
    R_wave_peak_times(Ri) = r_wave_peak_time;
end

%% Event-related analysis of ECG
% for each trial, define a stim period (onset of stim up to 1/2 toward onset of
% next stim). 
mean_RRintervals = nan(length(onsets)-1,2,3); % trials * window * parameter
npeaks = nan(length(onsets)-1,2,3); 

mean_QRS = nan(length(onsets)-1,2,3); % trials * window * parameter
mean_Ramp = nan(length(onsets)-1,2,3); % trials * window * parameter
mean_Rwavepeaktime = nan(length(onsets)-1,2,3); % trials * window * parameter

for tr = 1:length(onsets)-1
    stim_start = onsets(tr);
    next_stim_start = onsets(tr+1);
    half_sample = floor(mean([stim_start, next_stim_start]));

    % get locations of IBIs within stim and inter-stim period
    stim_locs = peakloc(peakloc>=stim_start & peakloc<half_sample);
    nostim_locs = peakloc(peakloc>=half_sample & peakloc<next_stim_start);
    
    % get average distance between peaks during stim and non-stim periods
    if stim_start >= stim_period_onsets(3) % third stim period
        mean_RRintervals(tr,1,3) = mean(diff(stim_locs));
        npeaks(tr,1,3) = length(diff(stim_locs));
        mean_RRintervals(tr,2,3) = mean(diff(nostim_locs));
        npeaks(tr,2,3) = length(diff(nostim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,3) = mean(QRS_durations(peakloc>=stim_start & peakloc<half_sample)-1); % skipping first beat
        mean_QRS(tr,2,3) = mean(QRS_durations(peakloc>=half_sample & peakloc<next_stim_start)-1); % skipping first beat
        
        mean_Ramp(tr,1,3) = mean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample)-1); % skipping first beat
        mean_Ramp(tr,2,3) = mean(R_amplitudes(peakloc>=half_sample & peakloc<next_stim_start)-1); % skipping first beat
        
        mean_Rwavepeaktime(tr,1,3) = mean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample)-1); % skipping first beat
        mean_Rwavepeaktime(tr,2,3) = mean(R_wave_peak_times(peakloc>=half_sample & peakloc<next_stim_start)-1); % skipping first beat
        
    elseif stim_start >= stim_period_onsets(2) % second stim period
        mean_RRintervals(tr,1,2) = mean(diff(stim_locs));
        npeaks(tr,1,2) = length(diff(stim_locs));
        mean_RRintervals(tr,2,2) = mean(diff(nostim_locs));
        npeaks(tr,2,2) = length(diff(nostim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,2) = mean(QRS_durations(peakloc>=stim_start & peakloc<half_sample)-1); % skipping first beat
        mean_QRS(tr,2,2) = mean(QRS_durations(peakloc>=half_sample & peakloc<next_stim_start)-1); % skipping first beat
        
        mean_Ramp(tr,1,2) = mean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample)-1); % skipping first beat
        mean_Ramp(tr,2,2) = mean(R_amplitudes(peakloc>=half_sample & peakloc<next_stim_start)-1); % skipping first beat
        
        mean_Rwavepeaktime(tr,1,2) = mean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample)-1); % skipping first beat
        mean_Rwavepeaktime(tr,2,2) = mean(R_wave_peak_times(peakloc>=half_sample & peakloc<next_stim_start)-1); % skipping first beat
        
    else % first stim period
        mean_RRintervals(tr,1,1) = mean(diff(stim_locs));
        npeaks(tr,1,1) = length(diff(stim_locs));
        mean_RRintervals(tr,2,1) = mean(diff(nostim_locs));
        npeaks(tr,2,1) = length(diff(nostim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,1) = mean(QRS_durations(peakloc>=stim_start & peakloc<half_sample)-1); % skipping first beat
        mean_QRS(tr,2,1) = mean(QRS_durations(peakloc>=half_sample & peakloc<next_stim_start)-1); % skipping first beat
        
        mean_Ramp(tr,1,1) = mean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample)-1); % skipping first beat
        mean_Ramp(tr,2,1) = mean(R_amplitudes(peakloc>=half_sample & peakloc<next_stim_start)-1); % skipping first beat
        
        mean_Rwavepeaktime(tr,1,1) = mean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample)-1); % skipping first beat
        mean_Rwavepeaktime(tr,2,1) = mean(R_wave_peak_times(peakloc>=half_sample & peakloc<next_stim_start)-1); % skipping first beat
        
    end

end
%% Plot event related data
target_metric = mean_Ramp; % mean_RRintervals, mean_QRS, mean_Ramp, mean_Rwavepeaktime

subplot(2,3,1)
tmp = squeeze(target_metric(:,:,1));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('30Hz Stim')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)

subplot(2,3,2)
tmp = squeeze(target_metric(:,:,2));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('1kHz Stim')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)

subplot(2,3,3)
tmp = squeeze(target_metric(:,:,3));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('30Hz Stim - 500us IPD')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)
 

subplot(2,3,4)
tmp = squeeze(target_metric(:,:,1));
tmp = tmp(~all(tmp==0,2),:);
plot(tmp,'o')
hold on
hline(nanmedian(tmp(:)),'k-')
refline
title('30Hz Stim')
legend('stim','nostim')
set(gca,'FontName','Arial','FontSize',14)

subplot(2,3,5)
tmp = squeeze(target_metric(:,:,2));
tmp = tmp(~all(tmp==0,2),:);
plot(tmp,'o')
refline
hold on
hline(nanmedian(tmp(:)),'k-')
title('1kHz Stim')
set(gca,'FontName','Arial','FontSize',14)

subplot(2,3,6)
tmp = squeeze(target_metric(:,:,3));
tmp = tmp(~all(tmp==0,2),:);
plot(tmp,'o')
hold on
hline(nanmedian(tmp(:)),'k-')
refline
title('30Hz Stim - 500us IPD')
set(gca,'FontName','Arial','FontSize',14)