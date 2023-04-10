function taVNS_cold_hand_immersion(amp, pw, freq, npulse, inDur, outDur, nTrials)
    %singleStimTrain.m Takes a single stim waveform and presents it once.
    %
    % Inputs: 
    %   amp: amplitude (in milliamps)
    %   pw: duration of single pulse (microseconds, see biphasic waveform.m)
    %   freq: how fast the pulses are delivered
    %   npulse: number of pulses in pulse train (with frequency, determines
    %       stimulation duration)
    % Outputs:
    %   none

% remind user to start in voltage mode
prompt = 'Switch to Current mode and press enter to stimulate.';
x = input(prompt);


d = daq.getDevices;

Stim = daq.createSession('ni');
addAnalogOutputChannel(Stim,'Dev1',1,'Voltage');% adds a channel
% with the handle Stim to the DAQs AO1 port.

% send control signal to set voltage to 0, prior to switching to Current Mode
outputSingleScan(Stim, 0);

params.sr = 100000; % sampling frequency
%% set local parameters
params.pw = pw; % pulse width (us)
params.freq = freq; % frequency of stim (Hz)
params.npulses = npulse;
params.duration_test = npulse/params.freq; % duration of pulse train (s)
params.amp = amp; % input in Vols
params.ipd=50;
% set session rate on DAQ
Stim.Rate = params.sr;

% Setup stimulation
buf = MakeStimBuffer(params);

% create paced breathing figure
fig = figure('Color','k','WindowState','maximized');

sp = get(gca,'Position');
set(gca,'XLim',[-50 50],'YLim',[-50 50]);
axis square;
axis off;
drawnow;

for t = 1:nTrials
    % display inhalation cue
    tic
    r = [logspace(1,2,inDur*60) repmat(10^2,1,60)];
    cmap = colormap(cool(length(r)));
    for i = 1:length(r)
        set(gca,'XLim',[-50 50],'YLim',[-50 50]);
        c = rectangle('Position',[0-(r(i)/2) 0-(r(i)/2) r(i) r(i)],...
            'Curvature',[1 1],...
            'EdgeColor','none',...
            'FaceColor',cmap(i,:));
        drawnow limitrate;
        pause(inDur/length(r));
        delete(c);
    end
    toc

    % initialize stim buffer
    queueOutputData(Stim, buf');

    % display exhalation cue
    tic
    r = [logspace(2,1,inDur*60) repmat(10^1,1,60)];
    cmap = flipud(colormap(cool(length(r))));
    for i = 1:length(r)
        set(gca,'XLim',[-50 50],'YLim',[-50 50]);
        c = rectangle('Position',[0-(r(i)/2) 0-(r(i)/2) r(i) r(i)],...
            'Curvature',[1 1],...
            'EdgeColor','none',...
            'FaceColor',cmap(i,:));
        drawnow limitrate;
        pause(outDur/length(r));

        % initiate stimulation
        if i == ceil((length(r)/outDur)*(outDur-1))
            Stim.startForeground         % stim on
            % pause(1); % wait 1 seconds after end of stimulation to move on.
            Stim.stop();
            Stim.release();
        end

        delete(c);
    end
    toc
end

prompt = 'Switch to Voltage mode if finished.';
x = input(prompt);

end
