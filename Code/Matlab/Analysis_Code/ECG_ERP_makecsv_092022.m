%% Analyze Raw Data
% This script performs basic analyses on the converted .acq files from
% Acqknowledge (raw physio data). 
% Script needs to start in the folder containing
% 'analyze_raw_physio_data.m'
set(0,'defaultfigurecolor',[1 1 1])
cd(fileparts(which('ECG_ERP_makecsv_092022.m')));
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
initials = 'QG';
data = load(['Physiology_tests' filesep  'September_Physio_Tests' filesep 'tVNS testing ' initials '.mat']);
Fs = 20000;
%% get rid of bad data at end of experiment (for tVNS Danielle.mat)
%data.data = data.data(1:40210900,:);

%% get onset of stimulation periods
ANIN = data.data(:,1);
ANIN_fs = 10000; % need to find the real sampling rate
stimFreq = 30;
hpFreq = 1000;
on_threshold = 0.2;
pulse_threshold=max(ANIN)/2;
min_dur=0.3;
padtime=0;
plot_debug=0;
flip = 0;
[onsets,offsets] = findStimulationPeriods(ANIN,ANIN_fs,stimFreq,hpFreq,on_threshold,min_dur,padtime,flip);
%% get peak locations
samples = 1:length(data.data);
[peakloc,peakmag] = peakfinder(data.data(:,2),0.5,0.5);

%% get onset and offset of stimulation periods
stim_period_onsets = [onsets(1) onsets(1+find(diff(onsets)>nanmean(diff(onsets))*10))];

% Define non-stim and stim periods
block_duration = Fs*5*60;
non_stim_period_onsets = (stim_period_onsets - block_duration-1);

% define samples in seconds and minutes
ts = samples/Fs;
tm = ceil(ts/60);

% define block times
block_onsets = sort([stim_period_onsets non_stim_period_onsets]);
block_times = zeros(length(ts),1);
for s = 1:length(block_times)
    b = find(s>=block_onsets,1,'last');
    if ~isempty(b)
        block_times(s) = b;
    end
end


%% Create table for each heartbeat
winsize = round(0.06*Fs);
Ri = 2;
peak_data = data.data(peakloc(Ri)-10000:peakloc(Ri)+10000,2);

QRS_durations = zeros(size(peakloc));
R_amplitudes = zeros(size(peakloc));
R_wave_peak_times = zeros(size(peakloc));
time_seconds = zeros(size(peakloc));
time_minutes = zeros(size(peakloc));
block_idx = zeros(size(peakloc));

for Ri = 2:length(peakloc)-1 % We skip the first and last beat
    % extract a single pulse
    peak_data = data.data(peakloc(Ri)-10000:peakloc(Ri)+10000,2);
    peak_data = peak_data - median(peak_data);
    %peak_data = peak_data - median(peak_data(1:round(winsize/4))); % use first 1000 samples as a baseline
    
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
    TR = round(length(peak_data_rotated)/2);

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

    % Get identifiers
    time_seconds(Ri) = ts(peakloc(Ri));
    time_minutes(Ri) = tm(peakloc(Ri));
    block_idx(Ri) = block_times(peakloc(Ri));
end

%% create table from data
PID = cell(size(peakloc)); PID(:) = {initials};
T = table(PID, time_seconds, time_minutes, block_idx, QRS_durations,...
    R_amplitudes, R_wave_peak_times,'VariableNames',{'PID','Second','Minute',...
    'Block','QRSduration','Ramplitude','Rwavepeaktime'});
%% write table
writetable(T,['Physiology_tests' filesep  'September_Physio_Tests' filesep 'tVNS testing ' initials '.csv'])
