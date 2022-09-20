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
initials = 'AP';
data = load(['Physiology_tests' filesep  'September_Physio_Tests' filesep 'tVNS testing ' initials '.mat']);
Fs = 20000;
%% get rid of bad data at end of experiment (for tVNS Danielle.mat)
%data.data = data.data(1:40210900,:);
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
clf
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
clf

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
clf
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
% Define non-stim and stim periods
block_duration = Fs*5*60;
non_stim_period_onsets = (stim_period_onsets - block_duration-1);
vline(non_stim_period_onsets,'g-')

%% Visualize ECG metrics
clf
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

%% For each heart beat, assign it to a block (8 blocks)
winsize = round(0.06*Fs);
peak_data = data.data(peakloc(Ri)-10000:peakloc(Ri)+10000,2);
block_onsets = sort([stim_period_onsets non_stim_period_onsets]);
block_data = cell(8,1);
QRS_durations = cell(8,1);
R_amplitudes = cell(8,1);
R_wave_peak_times = cell(8,1);

for b = 1:8
    tmp = zeros(1,length(peak_data));
    block_data{b} = tmp;
    QRS_durations{b} = NaN;
    R_amplitudes{b} = NaN;
    R_wave_peak_times{b} = NaN;
end

for Ri = 2:length(peakloc)-1 % We skip the first and last peak
    % extract a single pulse
    peak_data = data.data(peakloc(Ri)-10000:peakloc(Ri)+10000,2);
    peak_data = peak_data - median(peak_data);
    %peak_data = peak_data - median(peak_data(1:round(winsize/4))); % use first 1000 samples as a baseline
    b = find(peakloc(Ri)>=block_onsets,1,'last');
    if ~isempty(b)
        tmp = block_data{b};
        tmp = cat(1,tmp,peak_data');
        block_data{b} = tmp;
    
        % Because the start of the QRS complex sometimes does not dip just before
        % the R (no local minimum), we tilt the data to find the inflection point
        v = [1:length(peak_data); peak_data']';
        theta = 0.002; 
        rotation_matrix = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
        v = v*rotation_matrix;
        peak_data_rotated = v(:,2);
    
        nsamples = length(peak_data);
        samps = 1:length(peak_data);
        
        % Find R in window
        [R,TR] = max(peak_data_rotated);
            
        % Get Q and S position
        [Q,QR] = min(peak_data_rotated(TR-winsize:TR));
        QR = QR + TR-winsize;
        [S,SR] = min(peak_data_rotated(TR:TR+winsize));
        SR = SR + TR;
    
        % 1. Duration of QRS complex
        qrs_dur = (SR-QR)/Fs;
        QRS_durations{b} = [QRS_durations{b}, qrs_dur];
        % 2. R wave amplitude
        r_amp = data.data(peakloc(Ri),2) - peak_data(QR);
        R_amplitudes{b} = [R_amplitudes{b}, r_amp];
        % 3. R-wave peak time
        r_wave_peak_time = (round(length(peak_data)/2) - QR)/Fs;
        R_wave_peak_times{b} = [R_wave_peak_times{b}, r_wave_peak_time];
    end
end

%% plot each 
clf
cmap = [255, 225, 25; 0, 130, 200; 245, 130, 48; 220, 190, 255; 128, 0, 0; 0, 0, 128; 128, 128, 128; 0, 0, 0]/255;
for b = 1:8
    tmp = block_data{b};
    tt = (1:size(tmp,2))/Fs;

    plot(tt,mean(tmp),'linewidth',2,'color',cmap(b,:));
    hold on
end
legend({'Baseline','Concha1','Rest','Concha2','Rest','Canal1','Rest','Canal2'})

%% Plot average QRS duration
clf
n_data_points = max(cell2mat(cellfun(@size,QRS_durations,'UniformOutput',false)));
n_data_points = n_data_points(2);
boxdata = nan(n_data_points,length(block_data));
for b = 1:8
    boxdata(1:size(QRS_durations{b},2),b) = QRS_durations{b};
end
% remove outliers
groupmean = nanmean(boxdata(:));
groupstd = nanstd(boxdata(:));
boxdata(abs((boxdata-groupmean)./groupstd)>5) = NaN;
%boxplot(boxdata,'notch',1)
hold on
plot(nanmean(boxdata),'o-')
if any(strcmp(initials,{'PH','MQ','QG','CR'}))
    set(gca,'XTickLabel',{'Baseline','Concha1','Rest','Concha2','Rest','Canal1','Rest','Canal2'})
elseif any(strcmp(initials,{'IG','AP'}))
    set(gca,'XTickLabel',{'Baseline','Canal1','Rest','Canal2','Rest','Concha1','Rest','Concha2'})
else any(strcmp(initials,{'DL','JL'}))
    set(gca,'XTickLabel',{'Baseline','Sham1','Rest','Sham2','Rest','Sham3','Rest','Sham4'})

end
ylabel('QRS Duration (seconds)')
legend('Mean QRS duration')
title(initials)
ylim([nanmean(boxdata(:))-1*nanstd(boxdata(:)) nanmean(boxdata(:))+1*nanstd(boxdata(:))])

%% Plot average QRS duration
clf
n_data_points = max(cell2mat(cellfun(@size,QRS_durations,'UniformOutput',false)));
n_data_points = n_data_points(2);
boxdata = nan(n_data_points,length(block_data));
for b = 1:8
    boxdata(1:size(QRS_durations{b},2),b) = QRS_durations{b};
end
% remove outliers
groupmean = nanmean(boxdata(:));
groupstd = nanstd(boxdata(:));
boxdata(abs((boxdata-groupmean)./groupstd)>5) = NaN;
boxplot(boxdata,'notch',1)
hold on
plot(cellfun(@nanmean, QRS_durations),'o-');
if any(strcmp(initials,{'PH','MQ','QG','CR'}))
    set(gca,'XTickLabel',{'Baseline','Concha1','Rest','Concha2','Rest','Canal1','Rest','Canal2'})
elseif any(strcmp(initials,{'IG','AP'}))
    set(gca,'XTickLabel',{'Baseline','Canal1','Rest','Canal2','Rest','Concha1','Rest','Concha2'})
else any(strcmp(initials,{'DL','JL'}))
    set(gca,'XTickLabel',{'Baseline','Sham1','Rest','Sham2','Rest','Sham3','Rest','Sham4'})

end
ylabel('QRS Duration (seconds)')
legend('Mean QRS duration')
title(initials)

%% output data into a table/csv



%%
% 
% %%
% set(gca,'XTickLabel',{'Baseline','Concha1','Rest','Concha2','Rest','Canal1','Rest','Canal2'})
% subplot(2,1,2)
% plot(sdRR,'o-')
% vline([5 10 15 20 25 30 35 40])
% xlabel('Time (minutes)')