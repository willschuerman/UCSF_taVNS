# This stimulates using the given parameters
# 
from __future__ import division
		
def plotSampleWaveform(amp=0.1,freq=25,pw=200,ipd=50,npulse=15,sr=24414.0625):
    ##############################################################################################################
    ##############################################################################################################
    #   Import statements: Do not change
    ##############################################################################################################
    ##############################################################################################################
    import numpy as np
    import csv
    import sys
    import platform
    from scipy import signal
    import matplotlib.pyplot as plt
    import time


    params = {}
    params.update({"sr":sr, "amp":amp, "freq":freq, "pw":pw, 'npulse':npulse,'ipd':ipd})
    params.update({"duration_test":params['npulse']/params["freq"]})

    
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
        ptTest = constant_rate_pulser(params["freq"], params["duration_test"],params['sr'])
        #plt.plot(ptTest)
        yTest = signal.convolve(ptTest, wf)
        ypad = np.zeros(10) # add a small pad to beginning of buffer
        yTest = np.concatenate((ypad, yTest),axis=0)
        # %% generate the buffer
        # buf = np.zeros((params["nchan"],len(yTest)))
        # buf[1,:] = np.tile(yTest,[1,1])

        return yTest, ptTest, wf


    buf, ptTest, wf = MakeStimBuffer(params)
    buf_time = (np.arange(0,len(buf)))/params['sr']
    pt_time = (np.arange(0,len(ptTest)))/params['sr']
    wf_time = (np.arange(0,len(wf)))/params['sr']

    fig, axs = plt.subplots(3)
    axs[0].plot(pt_time,ptTest)
    axs[1].plot(wf_time,wf,'o-')
    axs[2].plot(buf_time,buf)
    plt.show()
    return buf,buf_time, ptTest, wf
