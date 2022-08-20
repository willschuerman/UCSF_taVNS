%% convolve a pulse train with a waveform or waveforms
%
% y = convolve(pt, wf)
%
% pt - pulse train (logical array)
% wf - waveform or cell array of waveform
%      if cell array: length(wf) === sum(pt) 
%
% the sampling rate must be the same for both

function y = convolve(pt, wf)

    y = zeros(size(pt));
    ipt = find(pt);
    dp = diff(ipt);
    bad = false(size(ipt));
    
    cwf = iscell(wf);
    
    if cwf
        if length(wf) ~= sum(pt)
            error('if wf is a cell array, length(wf) === sum(pt)');
        end
        n = cellfun(@length, wf);
        bad(2:end) = dp < n(1:end-1);
    else
        n = length(wf);
        bad(2:end) = dp < n; 
    end
    
    fprintf('removed %d pulses that overlapped\n', sum(bad));
    ipt(bad) = []; % dont allow overlapping pulses

    for i=1:length(ipt)
        if cwf
            y(ipt(i):ipt(i)+n(i)-1) = wf{i};
        else
            y(ipt(i):ipt(i)+n-1) = wf;
        end
    end

end