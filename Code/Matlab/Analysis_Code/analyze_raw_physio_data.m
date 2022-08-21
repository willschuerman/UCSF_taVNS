%% Analyze Raw Data
% This script performs basic analyses on the converted .acq files from
% Acqknowledge (raw physio data). 

%% Change directory to data folder

cd(['..' filesep '..' filesep '..'])
cd('Data')

%% Load data

data = load(['Physiology_tests' filesep 'tVNS Danielle.mat']);

%% plot raw data (subsampled)
subplot(3,1,1)
plot(data.data(1:50:end,1))
title('Stimulator Output')
subplot(3,1,2)
plot(data.data(1:50:end,2))
title('Electrocardiogram')
subplot(3,1,3)
plot(data.data(1:50:end,3))
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
subplot(3,1,1)
plot(data.data(onsets(1)-10000:onsets(3),1))
title('Stimulator Output')
subplot(3,1,2)
plot(data.data(onsets(1)-10000:onsets(3),2))
title('ECG')
subplot(3,1,3)
plot(data.data(onsets(1)-10000:onsets(3),3))
title('PPG')