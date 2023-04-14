function taVNS_cold_hand_immersion(amp, stimFlag, pw, freq, npulse, inDur, outDur, nTrials)
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

% DEFAULTS
if nargin < 1; error('PLEASE ENTER AMPLITUDE!'); end;
if nargin < 8
    if ~exist('pw','var'); pw = 100; end;
    if ~exist('freq','var'); freq = 30; end;
    if ~exist('npulse','var'); npulse = 30; end;
    if ~exist('inDur','var'); inDur = 2.9; end;
    if ~exist('outDur','var'); outDur = 3.7; end;
    if ~exist('nTrials','var'); nTrials = 30; end;
    if ~exist('stimFlag','var'); stimFlag = 1; end;
end

% remind user to start in voltage mode
fprintf('General parameters should be amp=[thresh], stimFlag=[experimenter decides], pw=100, freq=30, npulse=30, inDur=XX, outDur=XX, nTrials=XX\n')
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
fprintf('Press ENTER to begin\n');
waitforbuttonpress;

% practice trials
for t = 1:nTrials + 10
        % display inhalation cue
    tic
    r = [logspace(1,2,inDur*60) repmat(10^2,1,60)];
    cmap = colormap(cool(length(r)));
%     set(gca,'XLim',[-50 50],'YLim',[-50 50]);
    inst1 = text(0,-55,{'Breathe in through','your nose'},'HorizontalAlignment','center',...
        'FontSize',20,...
        'Color','w');
    hold on;
    for i = 1:length(r)
        set(gca,'XLim',[-50 50],'YLim',[-50 50]);
        c = rectangle('Position',[0-(r(i)/2) 0-(r(i)/2) r(i) r(i)],...
            'Curvature',[1 1],...
            'EdgeColor','none',...
            'FaceColor',cmap(1,:));
        drawnow limitrate;
        pause(inDur/length(r));
        delete(c);
    end
    toc

    delete(inst1);

    if stimFlag && (t > 3) && (t <= nTrials + 2)
        % initialize stim buffer
        queueOutputData(Stim, buf');
        prepare(Stim);
    end

    % display exhalation cue
    tic
    r = [logspace(2,1,inDur*60)]; % repmat(10^1,1,60)];
    cmap = flipud(colormap(cool(length(r))));
    inst2 = text(0,-55,{'Breathe out through','your mouth'},'HorizontalAlignment','center',...
        'FontSize',20,...
        'Color','w');
    for i = 1:length(r)
        set(gca,'XLim',[-50 50],'YLim',[-50 50]);
        c = rectangle('Position',[0-(r(i)/2) 0-(r(i)/2) r(i) r(i)],...
            'Curvature',[1 1],...
            'EdgeColor','none',...
            'FaceColor',cmap(end,:));
        drawnow limitrate;
        pause(outDur/length(r));

        if stimFlag && (t > 3) && (t <= nTrials + 2)
            % initiate stimulation
            if i == ceil((length(r)/outDur)*(outDur-0.3))
                tic
                Stim.startBackground         % stim on
                toc
                % pause(1); % wait 1 seconds after end of stimulation to move on.
%                 Stim.stop();
%                 Stim.release();
            end
        else
            if i == ceil((length(r)/outDur)*(outDur-0.3))
                pause(0.07);
            end
        end
        delete(c);
    end
    
    toc
    delete(inst2);

    if t == 2
        waitforbuttonpress;
    end
end

prompt = 'Switch to Voltage mode if finished.';
x = input(prompt);

end
