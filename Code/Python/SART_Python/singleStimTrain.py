# This stimulates using the given parameters
# 
from __future__ import division
		
def singleStimTrain(amp=0.1,freq=25,pw=200,npulse=15,plot=0):
    ##############################################################################################################
    ##############################################################################################################
    #   Import statements: Do not change
    ##############################################################################################################
    ##############################################################################################################
    import numpy as np
    import csv
    import sys
    import platform
    import nidaqmx
    from nidaqmx import constants
    from nidaqmx.stream_writers import AnalogSingleChannelWriter
    from scipy import signal
    import matplotlib.pyplot as plt
    import time


    params = {}
    params.update({"sr":24000.00, "amp":amp, "freq":freq, "pw":pw, 'npulse':npulse})
    params.update({"duration_test":params['npulse']/params["freq"]})

    
    ##############################################################################################################
    ##############################################################################################################
    #	tVNS Setup
    ##############################################################################################################
    ##############################################################################################################

    system = nidaqmx.system.System.local()
    system.driver_version

    for device in system.devices:
        print(device)

    def biphasic_waveform(amp, pw, ipd=0, sr=24414.0625):

        pws = np.floor(pw*sr/1e6) 
        ipds = np.floor(ipd*sr/1e6)

        wf = np.zeros(int(pws*2+ipds))
        wf[:int(pws)] = -amp
        wf[len(wf)-int(pws):] = amp
        wf = np.append(wf,0) # ensure that last sample is zero
        return wf


    def constant_rate_pulser(f, dur, sr=24414.0625):

        ipis = np.floor(sr/f)
        durs = np.floor(dur*sr)

        pt = np.zeros(int(durs))
        for i in range(0, int(durs-ipis),int(ipis)):
            pt[i] = 1

        return pt


    def MakeStimBuffer(params):
        #print params
        # %% generate the biphasic waveform
        wf = biphasic_waveform(params["amp"], params["pw"],ipd=50)
        #print wf
        # %% generate the train for the test block
        # % create the 30Hz train
        ptTest = constant_rate_pulser(params["freq"], params["duration_test"])
        #plt.plot(ptTest)
        yTest = signal.convolve(ptTest, wf)
        ypad = np.zeros(100)
        yTest = np.concatenate((ypad, yTest),axis=0)
        # %% generate the buffer
        # buf = np.zeros((params["nchan"],len(yTest)))
        # buf[1,:] = np.tile(yTest,[1,1])

        return yTest


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
        # Stimulate

        #task.write(list(buf), auto_start=True) # I think this should work...
        writer.write_many_sample(buf)
        start_time = time.time()
        task.start()
        task.wait_until_done(10)
        task.stop()
        print("--- %s seconds ---" % (time.time() - start_time))

    if plot:
        plt.plot(buf_time,buf)
        plt.show()
