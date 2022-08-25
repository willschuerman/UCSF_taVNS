%% Analyze Raw Data
% This script performs basic analyses on the converted .acq files from
% Acqknowledge (raw physio data). 
set(0,'defaultfigurecolor',[1 1 1])
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


%% get ECG metrics
close all
% extract a single pulse
peak_data = data.data(peakloc(2)-10000:peakloc(2)+10000,2);
peak_deriv = diff(peak_data);
nsamples = length(peak_data);
samps = 1:length(peak_data);
% get Q position

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

localmaxs = islocalmax(peak_data(1:Qi),'MinProminence',0.1);
Pi = max(find(localmaxs));
scatter(Pi,peak_data(Pi),'filled')



%% 

%% Event-related analysis of ECG
% for each trial, define a stim period (onset of stim up to 1/2 towoard onset of
% next stim). 
rr_intervals = nan(length(onsets)-1,2,3); % trials * window * parameter
qrs_intervals = nan(length(onsets)-1,2,3); % trials * window * parameter
npeaks = nan(length(onsets)-1,2,3);

for tr = 1:length(onsets)-1
    stim_start = onsets(tr);
    next_stim_start = onsets(tr+1);
    half_sample = floor(mean([stim_start, next_stim_start]));

    % get locations of IBIs within stim and inter-stim period
    stim_locs = peakloc(peakloc>=stim_start & peakloc<half_sample);
    nostim_locs = peakloc(peakloc>=half_sample & peakloc<next_stim_start);
    
    % get average distance between peaks during stim and non-stim periods
    if stim_start >= stim_period_onsets(3)
        rr_intervals(tr,1,3) = mean(diff(stim_locs));
        npeaks(tr,1,3) = length(diff(stim_locs));
        rr_intervals(tr,2,3) = mean(diff(nostim_locs));
        npeaks(tr,2,3) = length(diff(nostim_locs));
    elseif stim_start >= stim_period_onsets(2)
        rr_intervals(tr,1,2) = mean(diff(stim_locs));
        npeaks(tr,1,2) = length(diff(stim_locs));
        rr_intervals(tr,2,2) = mean(diff(nostim_locs));
        npeaks(tr,2,2) = length(diff(nostim_locs));
    else
        rr_intervals(tr,1,1) = mean(diff(stim_locs));
        npeaks(tr,1,1) = length(diff(stim_locs));
        rr_intervals(tr,2,1) = mean(diff(nostim_locs));
        npeaks(tr,2,1) = length(diff(nostim_locs));
    end

    % get mean qrs duration for stim vs nostim
    qrs_values = [];
    for s = 1:length(stim_locs)
        peak_data = data.data(stim_locs(s)-10000:stim_locs(s)+10000,2);
        localmins = islocalmin(peak_data(1:round(nsamples/2)),'MinProminence',0.01);
        Qi = max(find(localmins));
        localmins = islocalmin(peak_data(round(nsamples/2):end),'MinProminence',0.01);
        Si = round(nsamples/2)+min(find(localmins));
        qrs_values(s) = Si-Qi;
    end
    mean_qrs = mean(qrs_values);
    qrs_intervals(tr,2,1)

end
%% Plot event-related analysis

subplot(1,3,1)
tmp = squeeze(rr_intervals(:,:,1));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('30Hz Stim')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)

subplot(1,3,2)
tmp = squeeze(rr_intervals(:,:,2));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('1kHz Stim')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)

subplot(1,3,3)
tmp = squeeze(rr_intervals(:,:,3));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('30Hz Stim - 500us IPD')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)

linkaxes

%% 

subplot(1,3,1)
tmp = squeeze(rr_intervals(:,:,1));
tmp = tmp(~all(tmp==0,2),:);
plot(tmp,'o')
hold on
hline(nanmedian(tmp(:)),'k-')
refline
title('30Hz Stim')
legend('stim','nostim')
set(gca,'FontName','Arial','FontSize',14)

subplot(1,3,2)
tmp = squeeze(rr_intervals(:,:,2));
tmp = tmp(~all(tmp==0,2),:);
plot(tmp,'o')
refline
hold on
hline(nanmedian(tmp(:)),'k-')
title('1kHz Stim')
set(gca,'FontName','Arial','FontSize',14)

subplot(1,3,3)
tmp = squeeze(rr_intervals(:,:,3));
tmp = tmp(~all(tmp==0,2),:);
plot(tmp,'o')
hold on
hline(nanmedian(tmp(:)),'k-')
refline
title('30Hz Stim - 500us IPD')
set(gca,'FontName','Arial','FontSize',14)
linkaxes