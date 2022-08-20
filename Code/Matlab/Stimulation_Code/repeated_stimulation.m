function repeated_stimulation(stim_duration,ITI,pulse_train_duration,amplitude,frequency,pulse_width,ipd,waveform)
    %repeated_stimulation.m Takes a single stim waveform and repeats
    %stimulation for the specified duration
    %
    % Inputs: 
    %   stim_duration: the duration of the experiment (in seconds)
    %   ITI: vector [start end] representing random inter-trial-interval
    %      range (set to same number to have a fixed interval)
    %   pulse_train_duration: duration of stimulation (in seconds)
    %   amplitude: amplitude (in milliamps)
    %   frequency: how fast the pulses are delivered
    %   pulse_width: duration of single pulse (microseconds, see biphasic waveform.m)
    %   ipd: inter-pulse-distance (microseconds, see biphasic waveform.m)
    %   waveform: 'square' or 'sine'
    %
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
    
    params.sr = 44100; % sampling frequency

    %% set local parameters
    params.pw = pulse_width; % pulse width (us)
    params.freq = frequency; % frequency of stim (Hz)
    %params.npulses = npulse;
    params.duration_test = pulse_train_duration; % duration of pulse train (s)
    params.amp = amplitude; % input in Vols
    params.ipd = ipd;
    
    % set session rate on DAQ
    Stim.Rate = params.sr;
    
    % Setup stimulation
    if strcmp(waveform,'sine')
        buf = MakeStimBuffer_sinewave(params);
    else
        buf = MakeStimBuffer(params);
    end
    queueOutputData(Stim, buf');
    

    totalTimer = tic;
    while toc(totalTimer) < stim_duration
        % determine ITI
        trial_iti = rand(1);
        trial_iti = trial_iti*(ITI(2)-ITI(1))+ITI(1);
        % initiate stimulation
        Stim.startForeground         % stim on
        pause(trial_iti); % wait ITI
        Stim.stop();
        queueOutputData(Stim, buf');
        disp(toc(totalTimer))
    end
    Stim.stop();
    Stim.release();
    
    prompt = 'Switch to Voltage mode if finished.';
    x = input(prompt);
end