%% make a symmetric, biphasic, cathode-leading ("Lilly") waveform
%
% wf = monophasic_waveform(amp, pw, [ipd], [sr])
%
%
% ipd defaults to 0 us
% sr defaults 24414.0625 Hz

function wf = monophasic_waveform(amp, pw, varargin)

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
        sr = 24414.0625;
    end
   
    pws = floor(pw*sr/1e6);
    ipds = floor(ipd*sr/1e6);
    
    wf = zeros(1,pws+ipds); 
    wf(1:pws) = amp;
    wf(end+1) = 0; % ensure that last sample is zero
end