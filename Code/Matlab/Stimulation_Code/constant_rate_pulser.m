%% generate a regular, constant-frequency pulse train
%
% pt = constant_rate_pulser(f, dur, [sr])
%
% f is pulse repetition rate [Hz]
% dur is pulse train duration in [s]
%
% sr defaults 24414.0625 Hz

function pt = constant_rate_pulser(f, dur, varargin)

    narginchk(1, 3);
    
    sr = [];
    
    if nargin == 3
        sr = varargin{1};
    end
    
    ipis = floor(sr/f);
    durs = floor(dur*sr);
    
    pt = false(1, durs);
    count = 0;
    for i=1:ipis:(durs-ipis)
        pt(i) = true;
        count = count+1;
    end
end