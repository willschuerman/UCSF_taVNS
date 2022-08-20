%% make a symmetric, biphasic, cathode-leading ("Lilly") waveform
%
% wf = biphasic_waveform(amp, pw, [ipd], [sr])
%
% amp [uA]        +----+
% pw  [us]        |    |
% ipd [us]        |    |
%                 |    |
% -------+    +---+    +-------
%        |    | \
% (amp)--|    |  (ipd)
%        |    |
%        +----+
%           \
%            (pw)
%
% ipd defaults to 0 us
% sr defaults 24414.0625 Hz

function wf = biphasic_waveform(amp, pw, varargin)

    narginchk(2, 4);
    
    ipd = [];
    sr = [];
    
    switch nargin
        case 3
            ipd = varargin{1};
        case 4
            ipd = varargin{1};
            sr = varargin{2};
    end
    
    if isempty(ipd)
        ipd = 0;
    end
    
    if isempty(sr)
        sr = 24414;
        pws = floor(pw*sr/1e6);
        ipds = floor(ipd*sr/1e6);
    else
        if sr < 1000
            pws = floor(pw*sr/1e4);
            ipds = floor(ipd*sr/1e4);
        elseif sr >= 1000 && sr <= 9999
            pws = floor(pw*sr/1e5);
            ipds = floor(ipd*sr/1e5);
        elseif sr >= 10000
            pws = floor(pw*sr/1e6);
            ipds = floor(ipd*sr/1e6);  
        elseif sr >= 100000
            pws = floor(pw*sr/1e7);
            ipds = floor(ipd*sr/1e7);
        end
            
    end
   

    
    wf = zeros(1,pws*2+ipds); 
    wf(1:pws) = -amp;
    wf(end-pws+1:end) = amp;
    wf(end+1) = 0; % ensure that last sample is zero
end