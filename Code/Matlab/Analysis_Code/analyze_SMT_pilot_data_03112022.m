%% Analyze Raw Data
% This script performs basic analyses on the converted .acq files from
% Acqknowledge (raw physio data). 
% Script needs to start in the folder containing
% 'analyze_raw_physio_data.m'
set(0,'defaultfigurecolor',[1 1 1])

%% Background 
% Baker & Baker, 1955: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5624990/
% -epinephrine and norepinephrine increase the magnitude of the QRS complex
% (R_amplitude)
% -acetylcholine depresses the QRS-complex (R_amplitude)

% Buschmann et al., 1995: https://pubmed.ncbi.nlm.nih.gov/6160328/
% -adrenaline and noradrenaline widen the QRS complex

%% Add Current folder then Change directory to data folder
addpath(genpath(pwd()))
cd(['..' filesep '..' filesep '..'])
cd('Data')

%% Load data
PID = '901';
data = load(['SART_Tests' filesep 'SMT_' PID '.mat']);
ANIN_fs = 10000;
fs = 1250;
%% get rid of bad data at end of experiment (for tVNS Danielle.mat)
%data.data = data.data(1:40210900,:);
%% plot raw data
t = linspace(0,length(data.data)/ANIN_fs,length(data.data));

for p = 1:size(data.data,2)
    subplot(size(data.data,2),1,p)
    plot(t(1:10:end)/60,data.data(1:10:end,p))
    title(data.labels(p,:))
end
xlabel('Time (m)')
%% close windows
close all
%% plot raw data

plot(t/60,data.data(:,2)-mean(data.data(:,2)))
title(data.labels(2,:))
xlabel('Time (minutes)')

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
[peakloc,peakmag] = peakfinder(data.data(:,2),0.5,0.5);
plot(samples,data.data(:,2))
hold on
scatter(samples(peakloc),data.data(peakloc,2))

%% get onset and offset of stimulation periods
stim_period_onsets = [onsets(1) onsets(1+find(diff(onsets)>nanmean(diff(onsets))*10))];
plot(data.data(:,1))
title('Stimulator Output')
hold on
vline(stim_period_onsets,'r-')


%% Visualize ECG metrics
close all
% extract a single pulse
Ri = 24;
peak_data = data.data(peakloc(Ri)-10000:peakloc(Ri)+10000,2);
peak_data = peak_data - median(peak_data);

% Because the start of the QRS complex sometimes does not dip just before
% the R (no local minimum), we tilt the data to find the inflection point
v = [1:length(peak_data); peak_data']';
theta = 0.002; 
rotation_matrix = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
plot(v(:,1),v(:,2));
hold on
v = v*rotation_matrix;
plot(v(:,1),v(:,2));
peak_data_rotated = v(:,2);

%peak_deriv = diff(peak_data);
nsamples = length(peak_data);
samps = 1:length(peak_data);
t    = [0:nsamples-1]/Fs;
winsize = round(0.06*Fs); % window for searching for Q and S

% Find R in window
[R,TR] = max(peak_data_rotated);

plot(peak_data_rotated)
hold on
plot(TR-winsize:TR+winsize,peak_data_rotated(TR-winsize:TR+winsize))
% Define Q as the minimum within window preceding R peak
[Q,QR] = min(peak_data_rotated(TR-winsize:TR));
QR = QR + TR-winsize;
scatter(QR,Q,'filled')

% Define S as the minimum within window following R peak
[S,SR] = min(peak_data_rotated(TR:TR+winsize));
SR = SR + TR;
scatter(SR,S,'filled')

%% For each heart beat, extract the following metrics
% https://ecgwaves.com/topic/ecg-normal-p-wave-qrs-complex-st-segment-t-wave-j-point/
% 1. Duration of QRS complex (note, due to ease of computation, Q and S are 
% measured as the local minimum relative to R, not the zero-crossing).  
% 2. Amplitude of R relative to Q.
% 3. R-wave peak time (peak of R relative to Q)
% 4. QR Slope

QRS_durations = zeros(length(peakloc),1);
R_amplitudes = zeros(length(peakloc),1);
R_wave_peak_times = zeros(length(peakloc),1);
QR_slopes = zeros(length(peakloc),1);

for Ri = 2:length(peakloc)-1 % We skip the first and last peak
    % extract a single pulse
    peak_data = data.data(peakloc(Ri)-10000:peakloc(Ri)+10000,2);
    peak_data = peak_data - median(peak_data);

    % Because the start of the QRS complex sometimes does not dip just before
    % the R (no local minimum), we tilt the data to find the inflection point
    v = [1:length(peak_data); peak_data']';
    theta = 0.002; 
    rotation_matrix = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
    v = v*rotation_matrix;
    peak_data_rotated = v(:,2);

    nsamples = length(peak_data);
    samps = 1:length(peak_data);

    % Get Q and S position
    [Q,QR] = min(peak_data_rotated(TR-winsize:TR));
    QR = QR + TR-winsize;
    [S,SR] = min(peak_data_rotated(TR:TR+winsize));
    SR = SR + TR;

    % 1. Duration of QRS complex
    qrs_dur = (SR-QR)/Fs;
    QRS_durations(Ri) = qrs_dur;
    % 2. R wave amplitude
    r_amp = data.data(peakloc(Ri),2) - peak_data(QR);
    R_amplitudes(Ri) = r_amp;
    % 3. R-wave peak time
    r_wave_peak_time = (round(length(peak_data)/2) - QR)/Fs;
    R_wave_peak_times(Ri) = r_wave_peak_time;
    % 4. QR_slope
    qr_slope = (r_amp-peak_data(QR))/r_wave_peak_time;
end

%% Event-related analysis of ECG
% for each trial, define a stim period (onset of stim up to 1/2 toward onset of
% next stim). 
mean_RRintervals = nan(length(onsets)-1,2,4); % trials * window * parameter
npeaks = nan(length(onsets)-1,2,4); 

mean_QRS = nan(length(onsets)-1,2,4); % trials * window * parameter
mean_Ramp = nan(length(onsets)-1,2,4); % trials * window * parameter
mean_Rwavepeaktime = nan(length(onsets)-1,2,4); % trials * window * parameter

for tr = 1:length(onsets)-1
    stim_start = onsets(tr);
    next_stim_start = onsets(tr+1);
    half_sample = floor(nanmean([stim_start, next_stim_start]));

    % get locations of IBIs within stim and inter-stim period
    stim_locs = peakloc(peakloc>=stim_start & peakloc<half_sample);
    nostim_locs = peakloc(peakloc>=half_sample & peakloc<next_stim_start);
    
    % get average distance between peaks during stim and non-stim periods
    if stim_start >= stim_period_onsets(4) % third stim period
        mean_RRintervals(tr,1,4) = nanmean(diff(stim_locs));
        npeaks(tr,1,4) = length(diff(stim_locs));
        mean_RRintervals(tr,2,4) = nanmean(diff(nostim_locs));
        npeaks(tr,2,4) = length(diff(nostim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,4) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample)); 
        mean_QRS(tr,2,4) = nanmean(QRS_durations(peakloc>=half_sample & peakloc<next_stim_start)); 
        
        mean_Ramp(tr,1,4) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample)); 
        mean_Ramp(tr,2,4) = nanmean(R_amplitudes(peakloc>=half_sample & peakloc<next_stim_start)); 
        
        mean_Rwavepeaktime(tr,1,4) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample)); 
        mean_Rwavepeaktime(tr,2,4) = nanmean(R_wave_peak_times(peakloc>=half_sample & peakloc<next_stim_start)); 
            
    elseif stim_start >= stim_period_onsets(3) % third stim period
        mean_RRintervals(tr,1,3) = nanmean(diff(stim_locs));
        npeaks(tr,1,3) = length(diff(stim_locs));
        mean_RRintervals(tr,2,3) = nanmean(diff(nostim_locs));
        npeaks(tr,2,3) = length(diff(nostim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,3) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample)); 
        mean_QRS(tr,2,3) = nanmean(QRS_durations(peakloc>=half_sample & peakloc<next_stim_start)); 
        
        mean_Ramp(tr,1,3) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample)); 
        mean_Ramp(tr,2,3) = nanmean(R_amplitudes(peakloc>=half_sample & peakloc<next_stim_start)); 
        
        mean_Rwavepeaktime(tr,1,3) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample)); 
        mean_Rwavepeaktime(tr,2,3) = nanmean(R_wave_peak_times(peakloc>=half_sample & peakloc<next_stim_start)); 
        
    elseif stim_start >= stim_period_onsets(2) % second stim period
        mean_RRintervals(tr,1,2) = nanmean(diff(stim_locs));
        npeaks(tr,1,2) = length(diff(stim_locs));
        mean_RRintervals(tr,2,2) = nanmean(diff(nostim_locs));
        npeaks(tr,2,2) = length(diff(nostim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,2) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample));
        mean_QRS(tr,2,2) = nanmean(QRS_durations(peakloc>=half_sample & peakloc<next_stim_start));
        
        mean_Ramp(tr,1,2) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample));
        mean_Ramp(tr,2,2) = nanmean(R_amplitudes(peakloc>=half_sample & peakloc<next_stim_start));
        
        mean_Rwavepeaktime(tr,1,2) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample));
        mean_Rwavepeaktime(tr,2,2) = nanmean(R_wave_peak_times(peakloc>=half_sample & peakloc<next_stim_start));
        
    else % first stim period
        mean_RRintervals(tr,1,1) = nanmean(diff(stim_locs));
        npeaks(tr,1,1) = length(diff(stim_locs));
        mean_RRintervals(tr,2,1) = nanmean(diff(nostim_locs));
        npeaks(tr,2,1) = length(diff(nostim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,1) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample));
        mean_QRS(tr,2,1) = nanmean(QRS_durations(peakloc>=half_sample & peakloc<next_stim_start));
        
        mean_Ramp(tr,1,1) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample));
        mean_Ramp(tr,2,1) = nanmean(R_amplitudes(peakloc>=half_sample & peakloc<next_stim_start));
        
        mean_Rwavepeaktime(tr,1,1) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample));
        mean_Rwavepeaktime(tr,2,1) = nanmean(R_wave_peak_times(peakloc>=half_sample & peakloc<next_stim_start));
        
    end

end
%% Plot event related data
target_metric = mean_Rwavepeaktime; % mean_RRintervals, mean_QRS, mean_Ramp, mean_Rwavepeaktime

subplot(1,4,1)
tmp = squeeze(target_metric(:,:,1));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('Concha Stim1')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)

subplot(1,4,2)
tmp = squeeze(target_metric(:,:,2));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('Concha Stim2')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)

subplot(1,4,3)
tmp = squeeze(target_metric(:,:,3));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('Canal Stim1')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)
 
subplot(1,4,4)
tmp = squeeze(target_metric(:,:,4));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('Canal Stim2')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)
linkaxes
 
%% Compare metrics during stim blocks and non-stim blocks

block_duration = 5*60*Fs; % in samples
fake_onsets = onsets-block_duration;
%% Event-related analysis of ECG
% for each trial, define a stim period (onset of stim up to 1/2 toward onset of
% next stim). 
mean_RRintervals = nan(length(onsets)-1,2,4); % trials * window * parameter
npeaks = nan(length(onsets)-1,2,4); 

mean_QRS = nan(length(onsets)-1,2,4); % trials * window * parameter
mean_Ramp = nan(length(onsets)-1,2,4); % trials * window * parameter
mean_Rwavepeaktime = nan(length(onsets)-1,2,4); % trials * window * parameter

for tr = 1:length(onsets)-1
    % record data during verum stim
    stim_start = onsets(tr);
    next_stim_start = onsets(tr+1);
    half_sample = next_stim_start - 100; % unlike previous analysis, use whole trial window

    % get locations of IBIs within stim and inter-stim period
    stim_locs = peakloc(peakloc>=stim_start & peakloc<half_sample);
    
    % get average distance between peaks during stim and non-stim periods
    if stim_start >= stim_period_onsets(4) % third stim period
        mean_RRintervals(tr,1,4) = nanmean(diff(stim_locs));
        npeaks(tr,1,4) = length(diff(stim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,4) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample)); 
        mean_Ramp(tr,1,4) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample));
        mean_Rwavepeaktime(tr,1,4) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample)); 

    elseif stim_start >= stim_period_onsets(3) % third stim period
        mean_RRintervals(tr,1,3) = nanmean(diff(stim_locs));
        npeaks(tr,1,3) = length(diff(stim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,3) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample)); 
        mean_Ramp(tr,1,3) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample));
        mean_Rwavepeaktime(tr,1,3) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample)); 
        
    elseif stim_start >= stim_period_onsets(2) % second stim period
        mean_RRintervals(tr,1,2) = nanmean(diff(stim_locs));
        npeaks(tr,1,2) = length(diff(stim_locs));
        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,2) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample));
        mean_Ramp(tr,1,2) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample));
        mean_Rwavepeaktime(tr,1,2) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample));
        
    else % first stim period
        mean_RRintervals(tr,1,1) = nanmean(diff(stim_locs));
        npeaks(tr,1,1) = length(diff(stim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,1,1) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample));
        mean_Ramp(tr,1,1) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample));
        mean_Rwavepeaktime(tr,1,1) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample));
        
    end

    % record data during resting state (using same timing information)
    stim_start = fake_onsets(tr);
    next_stim_start = fake_onsets(tr+1);
    half_sample = next_stim_start - 100; % unlike previous analysis, use whole trial window

    % get locations of IBIs within stim and inter-stim period
    stim_locs = peakloc(peakloc>=stim_start & peakloc<half_sample);
    
    % get average distance between peaks during stim and non-stim periods
    if stim_start >= stim_period_onsets(3) % third non-stim period
        mean_RRintervals(tr,2,4) = nanmean(diff(stim_locs));
        npeaks(tr,2,4) = length(diff(stim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,2,4) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample)); 
        mean_Ramp(tr,2,4) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample));
        mean_Rwavepeaktime(tr,2,4) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample)); 
        
    elseif stim_start >= stim_period_onsets(2) % third non-stim period
        mean_RRintervals(tr,2,3) = nanmean(diff(stim_locs));
        npeaks(tr,2,3) = length(diff(stim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,2,3) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample)); 
        mean_Ramp(tr,2,3) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample));
        mean_Rwavepeaktime(tr,2,3) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample)); 
        
    elseif stim_start >= stim_period_onsets(1) % second non-stim period
        mean_RRintervals(tr,2,2) = nanmean(diff(stim_locs));
        npeaks(tr,2,2) = length(diff(stim_locs));
        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,2,2) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample));
        mean_Ramp(tr,2,2) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample));
        mean_Rwavepeaktime(tr,2,2) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample));
        
    else % first stim period
        mean_RRintervals(tr,2,1) = nanmean(diff(stim_locs));
        npeaks(tr,2,1) = length(diff(stim_locs));

        % Get average QRS metrics for stim and non-stim periods
        mean_QRS(tr,2,1) = nanmean(QRS_durations(peakloc>=stim_start & peakloc<half_sample));
        mean_Ramp(tr,2,1) = nanmean(R_amplitudes(peakloc>=stim_start & peakloc<half_sample));
        mean_Rwavepeaktime(tr,2,1) = nanmean(R_wave_peak_times(peakloc>=stim_start & peakloc<half_sample));
        
    end
end

%% Plot event related data
target_metric = mean_RRintervals; % mean_RRintervals, mean_QRS, mean_Ramp, mean_Rwavepeaktime

subplot(2,4,1)
tmp = squeeze(target_metric(:,:,1));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('Concha 1')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)

subplot(2,4,2)
tmp = squeeze(target_metric(:,:,2));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('Concha 2')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)

subplot(2,4,3)
tmp = squeeze(target_metric(:,:,3));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('Canal 1')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)

subplot(2,4,4)
tmp = squeeze(target_metric(:,:,4));
tmp = tmp(~all(tmp==0,2),:);
boxplot(tmp,notch=1)
hold on
hline(nanmedian(tmp(:)),'k-')
title('Canal 2')
set(gca,'XTickLabel',{'Stim','NoStim'})
set(gca,'FontName','Arial','FontSize',14)
  

subplot(2,4,5)
tmp = squeeze(target_metric(:,:,1));
tmp = tmp(~all(tmp==0,2),:);
plot(tmp,'o')
hold on
hline(nanmedian(tmp(:)),'k-')
refline
title('Concha 1')
legend('stim','nostim')
set(gca,'FontName','Arial','FontSize',14)

subplot(2,4,6)
tmp = squeeze(target_metric(:,:,2));
tmp = tmp(~all(tmp==0,2),:);
plot(tmp,'o')
refline
hold on
hline(nanmedian(tmp(:)),'k-')
title('Concha 2')
set(gca,'FontName','Arial','FontSize',14)

subplot(2,4,7)
tmp = squeeze(target_metric(:,:,3));
tmp = tmp(~all(tmp==0,2),:);
plot(tmp,'o')
hold on
hline(nanmedian(tmp(:)),'k-')
refline
title('Canal 1')
set(gca,'FontName','Arial','FontSize',14)

subplot(2,4,8)
tmp = squeeze(target_metric(:,:,4));
tmp = tmp(~all(tmp==0,2),:);
plot(tmp,'o')
hold on
hline(nanmedian(tmp(:)),'k-')
refline
title('Canal 2')
set(gca,'FontName','Arial','FontSize',14)


%% get metrics by minute over experiment

t = (1:length(data.data(:,1)))/Fs;
tm = t/60;

meanRR = zeros(round(max(tm)),1);
sdRR = zeros(round(max(tm)),1);


for m = 1:max(tm)
    if m ==max(tm)
        index_start = find(tm>=m,1);
        [~,index_stop] = max(tm);
    else
        index_start = find(tm>=m,1);
        index_stop = find(tm>=m+1,1);
    end
    RRdiff = diff(peakloc(peakloc>=index_start & peakloc<=index_stop));
    meanRR(m) = mean(RRdiff);
    sdRR(m) = std(RRdiff);
end
%%
subplot(2,1,1)
boxplot(reshape(meanRR,5,8))
hline(nanmedian(meanRR),'k-')
title('Mean R-R Interval')
set(gca,'XTickLabel',{'Baseline','Concha1','Rest','Concha2','Rest','Canal1','Rest','Canal2'})
subplot(2,1,2)
plot(meanRR,'o-')
vline([5 10 15 20 25 30 35 40])
xlabel('Time (minutes)')
%%
subplot(2,1,1)
boxplot(reshape(sdRR,5,8))
hline(nanmedian(sdRR),'k-')
title('Mean R-R Interval')
set(gca,'XTickLabel',{'Baseline','Concha1','Rest','Concha2','Rest','Canal1','Rest','Canal2'})
subplot(2,1,2)
plot(sdRR,'o-')
vline((5.5:5:40))
xlabel('Time (minutes)')

