
function singleStimTrainPlusSound(amp, pw, freq, npulse, soa,plotOutput,varargin)
    %singleStimTrainPlusSound.m Takes a single stim waveform and a single
    %sound file, and presents each once. 
    %
    % Inputs: 
    %   amp: amplitude (in milliamps)
    %   pw: duration of single pulse (microseconds, see biphasic waveform.m)
    %   freq: how fast the pulses are delivered
    %   npulse: number of pulses in pulse train (with frequency, determines
    %       stimulation duration)
    %   soa: stimulus-onset-asynchrony. How long to wait after stimulation
    %       has started before playing sound file.
    %   plotOutput: zero or one. If one, plots the stim waveform relative
    %       to the sound file. 
    %   varargin: optional label of sound file name (soundpath is currently
    %   set to 'vnsToneLearning/stim'
    % Outputs:
    %   none
    
    debug = 1; % this is hard coded. Manually change to zero to actually stimulate
    soa = soa/1000; % convert from milliseconds to seconds
    if ~isempty(varargin)
        sound_file_name = varargin{1};
    else
        sound_file_name = 'bu1-aN.wav';
    end
    soundpath = ['vnsToneLearning' filesep 'stim' filesep sound_file_name];
    [y,Fs] = audioread(soundpath); % Read .wav file
    p = audioplayer(y,Fs);       % load .wav file

    % remind user to start in voltage mode
    prompt = 'Switch to Current mode and press enter to stimulate.';
    input(prompt);

    if debug==0
        d = daq.getDevices;    
        Stim = daq.createSession('ni');
        addAnalogOutputChannel(Stim,'Dev1',1,'Voltage');% adds a channel
        % with the handle Stim to the DAQs AO1 port.
        
        % send control signal to set voltage to 0, prior to switching to Current Mode
        outputSingleScan(Stim, 0);
    end
    
    params.sr = Fs; % sampling frequency
    %% set local parameters
    params.pw = pw; % pulse width (us)
    params.freq = freq; % frequency of stim (Hz)
    params.npulses = npulse;
    params.duration_test = npulse/params.freq; % duration of pulse train (s)
    params.amp = amp; % input in Vols
    
    % set session rate on DAQ
    if debug == 0
        Stim.Rate = params.sr;
    end
    
    % Setup stimulation
    buf = MakeStimBuffer(params);

    if debug == 0
        queueOutputData(Stim, buf');
        % initiate stimulation
        Stim.startBackground;   % stim on, this does not halt other operations
    end
    if exist('WaitSecs','file')
        WaitSecs(soa); % Wait for the SOA (in ms) before starting the sound file
    else
        pause(soa);
    end
    play(p);
    %play(p, [1 (get(p, 'SampleRate') * 3)]);
    if exist('WaitSecs','file')
        WaitSecs(params.duration_test - soa);  % in case the sound file doesn't end on its own
    else
        pause(params.duration_test - soa);
    end
    if debug == 0
        Stim.stop()      
        Stim.release();
    end
    
    prompt = 'Switch to Voltage mode if finished.';
    input(prompt);

    if plotOutput
        figure
        minTime = 0-soa-0.1; % have 100ms of blank time prior to stim onset
        maxTime = max([params.duration_test length(y)/Fs])+0.2;
        timeVec = minTime:1/Fs:maxTime;
        
        [~,zeroIdx] = min(abs(timeVec));
        stimIdx = zeroIdx - round((soa)*Fs);

        soundVec = zeros(length(timeVec),1);
        stimVec = zeros(length(timeVec),1);

        soundVec(zeroIdx:zeroIdx+length(y)-1) = y;
        stimVec(stimIdx:stimIdx+length(buf)-1) = buf;
        sp(1) = subplot(2,1,1);
        plot(timeVec,soundVec)
        title('Sound')        
        ylabel('Current (mA)')
        ylims = get(gca,'YLim');
        hold on
        plot([0 0],ylims,'k-')
        set(gca,'FontName','Arial','FontSize',12)

        sp(2) = subplot(2,1,2);
        plot(timeVec,stimVec)
        title('tVNS')
        xlabel('Time (s)')
        ylabel('Current (mA)')
        linkaxes(sp,'x')
        ylims = get(gca,'YLim');
        hold on
        plot([0 0],[ylims(1)-0.25 ylims(2)+0.25],'k-')
        set(gca,'FontName','Arial','FontSize',12)
    end

end