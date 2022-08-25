function [onsets,offsets] = findStimulationPeriods(ANIN,ANIN_fs,stimFreq,hpFreq,on_threshold,min_dur,padtime,flip)
%findpulsesWithinTrials   Algorithm for detecting pulses during VNS stimulation.
%   [locs, onsets,offsets] = findpulsesWithinTrials(ANIN,ANIN_fs,stimFreq,hpFreq,pulse_threshold,min_dur): the mean value of the elements in X if X: a vector. 
%
%   ANIN: the analog signal (n*1) containing the pulse artifacts
%   ANIN_fs: the sampling rate of the analog signal
%   stimFreq: the rate of stimulation in Hertz
%   hpFreq: the frequency cutoff for the high-pass filter. If set to 0,
%   no filtering will be applied ot the analog signal.
%   pulse_threshold: the minimum amplitude for both a data point to be
%   considered as a pulse or part of a stim-on period.
%   min_dur: the minimum duration at which contiguous datapoints
%   exceeding the pulse_threshold will be considered a true on period.
    

%   set(0,'defaultfigurecolor',[1 1 1])

    % iVNS and tVNS-matched: stim_on_time = 11, duty_time = 19
        
    % 1. Broadly identify on periods from off periods
    % high pass filter the ekg signal, or flip the ANIN signal, and zscore
    % both.
    if hpFreq > 0
        Hd = designfilt('highpassfir','FilterOrder',20,'CutoffFrequency',hpFreq, ...
            'DesignMethod','window','Window',{@kaiser,3},'SampleRate',ANIN_fs);
        anin_filt = zscore(filtfilt(Hd,double(ANIN)));
    else
        if flip==1
            anin_filt = -1*zscore(double(ANIN));
        else
            anin_filt = zscore(double(ANIN));
        end
    end
    
    % get inter pulse distance
    t = linspace(0,length(anin_filt)/ANIN_fs,length(anin_filt));
    ipd = ceil((1./stimFreq)*ANIN_fs);
    
    % get a broad envelope of the signal
    % need to make this faster
    tmp = envelope(anin_filt);
    tmp = envelope(tmp,round(min(ipd)*4),'rms');
    env = tmp-min(tmp);
    %tmp = envelope(anin_filt,round(min(ipd)*4),'peaks');
    %env = envelope(tmp,round(min(ipd)/2),'peaks');

    is_stim_on = env>on_threshold;
    [onsets, offsets] = find_boolean_on(is_stim_on, 'set_dur_thresh',min_dur*ANIN_fs);

    % remove onsets/offsets that are too close together
    diff_onsets = diff(onsets);




    % Add in time before and after (not needed)
%     onsets = onsets - round(padtime*ANIN_fs);
%     offsets = offsets + round(padtime*ANIN_fs);

    % get rid of trials that exceed file size
    offsets(offsets > length(ANIN)) = [];
    onsets = onsets(1:length(offsets));
% 
%     % remove adjusted onsets prior to start of block
%     bad_onsets = onsets < 0;
%     onsets = onsets(~bad_onsets);
%     offsets = offsets(~bad_onsets);


end
    

