from __future__ import division
from time import perf_counter
import random
import numpy as np
#import csv
import sys
#import platform
from scipy import signal
import matplotlib.pyplot as plt
from easygui import *


##############################################################################################################
##############################################################################################################
#	tVNS Setup
##############################################################################################################
##############################################################################################################

def biphasic_waveform(amp, pw, ipd, sr):
# %
# % amp [uA]        +----+
# % pw  [us]        |    |
# % ipd [us]        |    |
# %                 |    |
# % -------+    +---+    +-------
# %        |    | \
# % (amp)--|    |  (ipd)
# %        |    |
# %        +----+
# %           \
# %            (pw)
# %
# % ipd defaults to 0 us
# % sr defaults 24414.0625 Hz

# duration of a single pulse cycle is 
# pw*2+ipd

    # set divisor based on sampling rate
    if sr < 1000:
        divisor = 1e4
    elif (sr >=1000) and (sr < 9999):
        divisor = 1e5
    elif (sr >= 10000) and (sr < 99999):
        divisor = 1e6
    elif sr >= 100000:
        divisor = 1e7
    
    # get pulse width and ipd in samples for a given sampling rate
    pws = np.ceil(pw*sr/divisor) 
    ipds = np.ceil(ipd*sr/divisor)

    # generate waveform
    wf = np.zeros(int(pws*2+ipds))
    wf[0:int(pws)] = -amp
    wf[-int(pws):] = amp
    wf = np.append(wf,0) # ensure that last sample is zero
    return wf


def constant_rate_pulser(f, dur, sr):

    ipis = np.floor(sr/f)
    durs = np.floor(dur*sr)

    pt = np.zeros(int(durs))
    for i in range(0, int(durs-ipis),int(ipis)):
        pt[i] = 1

    return pt

def MakeStimBuffer(params):
    #print params
    # %% generate the biphasic waveform
    wf = biphasic_waveform(params["amp"], params["pw"],params['ipd'],params['sr'])
    #print wf
    # %% generate the train for the test block
    # % create the 30Hz train
    ptTest = constant_rate_pulser(params["freq"], params["duration_stim"],params['sr'])
    #plt.plot(ptTest)
    yTest = signal.convolve(ptTest, wf)
    ypad = np.zeros(10) # add a small pad to beginning of buffer
    yTest = np.concatenate((ypad, yTest),axis=0)
    # %% generate the buffer
    # buf = np.zeros((params["nchan"],len(yTest)))
    # buf[1,:] = np.tile(yTest,[1,1])

    return yTest


#### SETUP EXPERIMENT #####

def get_expr_params():

    msg = "Define experiment parameters"
    title = "taVNS Experiment"
    fieldNames = ["Experiment Duration (seconds)","Inter-trial-interval (seconds) [interval]","Stim Duration (seconds)",
        "Amplitude (mA)","Frequency (Hz)","Pulse Width (microseconds)","Inter-pulse-distance (microseconds)",'Debug (no stim, 0 or 1)',
        'Waveform shape (square,sine,triangle']
    fieldValues = [5, [2,2.5],0.5,1,30,100,50,1,'square']  # we start with blanks for the values
    fieldValues = multenterbox(msg,title, fieldNames, fieldValues)
    

    # make sure that none of the fields was left blank
    if fieldValues == None: 
        sys.exit()
    for i in range(len(fieldNames)):
        if fieldValues[i].strip() == "":
            errmsg = errmsg + ('"%s" is a required field.\n\n' % fieldNames[i])

    # parse field values
    duration_expr = float(fieldValues[0])
    iti = fieldValues[1]
    if iti.find('[') != -1:
        tmp = iti.strip('[]')
        tmp = tmp.split(',')
        iti = [float(tmp[0]), float(tmp[1])]
    else:
        iti = float(iti)

    duration_stim = float(fieldValues[2])
    amp = float(fieldValues[3])
    freq = float(fieldValues[4])
    pw = float(fieldValues[5])
    ipd = float(fieldValues[6])
    debug = int(fieldValues[7])
    waveshape = fieldValues[8]

    params = {}
    params.update({'duration_expr':duration_expr,'iti':iti,"duration_stim":duration_stim})
    params.update({"sr":44100, "amp":amp, "freq":freq, "pw":pw,'ipd':ipd})
    params.update({'debug':debug})

    buf = MakeStimBuffer(params)
    buf_time = np.arange(0,len(buf))/params['sr']
    fig,ax = plt.subplots(2)
    fig.suptitle('Close plot to continue to next stage')
    ax[0].plot(buf_time,buf)
    ax[1].plot(buf_time[buf_time<0.005],buf[buf_time<0.005])
    plt.show()

    if ccbox(('Experiment will run for %d minutes (%d seconds). \nPress Continue to run experiment. \nPress Cancel to exit and start over.' % duration_expr/60, duration_expr),
        'Please confirm'):
        pass
    else:
        sys.exit()

    return params


#### RUN ACTUAL EXPERIMENT #####

params = get_expr_params()

if not params['debug']:
    import nidaqmx
    from nidaqmx import constants
    from nidaqmx.stream_writers import AnalogSingleChannelWriter
    system = nidaqmx.system.System.local()
    system.driver_version

    global task
    with nidaqmx.Task() as task:
        # Make stim buffer
        buf = MakeStimBuffer(params)
        buf_time = np.arange(0,len(buf))/params['sr']

        task.ao_channels.add_ao_voltage_chan("Dev1/ao1") # check output channel on DAQ
        #task.timing.cfg_samp_clk_timing(rate=params["sr"],samps_per_chan=len(buf))
        task.timing.cfg_samp_clk_timing(rate=params["sr"],
                                        sample_mode=constants.AcquisitionType.FINITE,  # FINITE or CONTINUOUS
                                        samps_per_chan=len(buf))
        writer = AnalogSingleChannelWriter(task.out_stream)


        # Start the stopwatch / counter
        expr_start = perf_counter()
        expr_stop = perf_counter()-expr_start

        # run the experiment for the target duration
        while expr_stop < params['duration_expr']:

            # get stim duration
            duration_stim = params['duration_stim']
            stim_start = perf_counter()
            stim_stop = perf_counter()-stim_start
            while stim_stop < duration_stim:

                # add stim code here
                print('stimulating...\n')
                writer.write_many_sample(buf)
                start_time = time.time()
                task.start()
                task.wait_until_done(10)
                task.stop()
                stim_stop = perf_counter()-stim_start
            print("--- %s seconds ---" % (stim_stop))


            # get inter-trial-interval
            if len(params['iti']) == 1:
                iti = params['iti']
            elif len(params['iti']) == 2:
                iti = random.random()*(params['iti'][1]-params['iti'][0])+params['iti'][0]

            iti_start = perf_counter()
            iti_stop = perf_counter()-iti_start
            while iti_stop < iti:
                iti_stop = perf_counter()-iti_start


            # Stop the stopwatch / counter
            expr_stop = perf_counter()-expr_start
else:
    # run a fake experiment

    # Start the stopwatch / counter
    expr_start = perf_counter()
    expr_stop = perf_counter()-expr_start

    # run the experiment for the target duration
    while expr_stop < params['duration_expr']:

        # get stim duration
        duration_stim = params['duration_stim']
        stim_start = perf_counter()
        stim_stop = perf_counter()-stim_start
        while stim_stop < duration_stim:
            print('fake stimulation...\n')
            stim_stop = perf_counter()-stim_start

        # get inter-trial-interval
        if len(params['iti']) == 1:
            iti = params['iti']
        elif len(params['iti']) == 2:
            iti = random.random()*(params['iti'][1]-params['iti'][0])+params['iti'][0]
        print('%f...\n' % iti)
        iti_start = perf_counter()
        iti_stop = perf_counter()-iti_start
        while iti_stop < iti:
            iti_stop = perf_counter()-iti_start


        # Stop the stopwatch / counter
        expr_stop = perf_counter()-expr_start
