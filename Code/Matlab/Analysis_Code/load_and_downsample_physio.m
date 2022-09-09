%% Load and downsample physio
% This script loads a .mat physiology data set and downsamples it for
% sharing. 
set(0,'defaultfigurecolor',[1 1 1])

%% Add Current folder then Change directory to data folder
addpath(genpath(pwd()))
cd(['..' filesep '..' filesep '..'])
cd('Data')

%% Load data
initials = 'AP';
data = load(['Physiology_tests' filesep 'September_Physio_Tests' filesep 'tVNS testing ' initials '.mat']);
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
close all

%% get onset of stimulation periods
ANIN = data.data(:,1);
ANIN_fs = Fs; % need to find the real sampling rate
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

%% create a binary variable indicating when stimulation was occurring
is_stim_on = zeros(length(data.data(:,1)),1);
for tr = 1:length(onsets)
    is_stim_on(onsets(tr):offsets(tr)) = 1;
end

%% downsample data to 100 samples a second
fs = 100;
[p,q] = rat(fs/Fs);
STIM = resample(is_stim_on,p,q);
ECG = resample(data.data(:,2),p,q); 
PPG = resample(data.data(:,3),p,q); 
%%
subplot(3,1,1)
plot(STIM)
subplot(3,1,2)
plot(ECG)
subplot(3,1,3)
plot(PPG)

%% save updated file
close all
save(['Physiology_tests' filesep 'September_Physio_Tests' filesep 'tVNS testing ' initials '_ds.mat'],'STIM','ECG','PPG','fs');
