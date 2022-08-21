function [onsets, offsets] = find_boolean_on(is_on, varargin)
% this function takes a boolean array and determines the time points where
% this boolean goes from OFF to ON (onsets) as well as the time points
% where the boolean goes from ON to OFF (offsets)
%
% If it stats or ends ON, it will add an offset/onset index at the
% start/end of the data
%
% Variable input - minimum_duration threshold (rejects intervals whose
% duration is less than a minimum length

%%
if length(varargin) > 0 
    if ~isempty(find(strcmpi(varargin,'set_dur_thresh')));
        set_dur_thresh = true;
        dur_thresh = varargin{find(strcmpi(varargin,'set_dur_thresh'))+1};
    else
        set_dur_thresh = true;
    end
    
    if ~isempty(find(strcmpi(varargin,'fs_in')));
        fs_in = varargin{find(strcmpi(varargin,'fs_in'))+1};
    else
        fs_in = 24000;
    end
    
    if ~isempty(find(strcmpi(varargin,'ERP_times')));
        ERP_times = varargin{find(strcmpi(varargin,'ERP_times'))+1};
    else
        ERP_times = [];
    end
else
    set_dur_thresh = false;
    
end

%%

is_on = is_on(:)'; % make input 1xn

onsets = find(diff(is_on)==1);
if is_on(1)
    onsets = [1 onsets];
end
offsets = find(diff(is_on) == -1);
if is_on(end)
    offsets = [offsets length(is_on)];
end

% Apply optional duration threshold
if set_dur_thresh
    exceed_dur_thresh = (offsets-onsets) > dur_thresh;
    onsets(~exceed_dur_thresh) = [];
    offsets(~exceed_dur_thresh) = [];
    
    if length(onsets) > 0 && ~isempty(ERP_times)
        if onsets(1) < abs(ERP_times(1))*fs_in;
            onsets(1) = [];
            offsets(1) = [];
        end
    end
end


end
