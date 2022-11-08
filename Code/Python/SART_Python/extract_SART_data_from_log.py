#%%
# Import packages
import os
import glob
import pandas as pd
import matplotlib.pyplot as plt
# %%
# Set directories
cur_dir = os.getcwd()
data_dir = cur_dir.replace('Code/Python/SART_Python','Data/SART_Microstudy')
# %%
# Get list of log files
file_list = glob.glob(data_dir + '/*.log')
# %%
# Read in tab separated log file (skipping practice trials)
log_data = pd.read_csv(file_list[0], sep='\t', lineterminator='\n',header=None,skiprows=108)
log_data.columns = ['Time','Event','Info']
log_data.head(100)

# %%
digit_start_idx = log_data['Info'].str.contains('digit start')
button_press_idx = log_data['Info'].str.contains('space')
log_data = log_data[digit_start_idx | button_press_idx]
log_data = log_data.sort_values(by=['Time'])
log_data = log_data.reset_index(drop='True')
# %%
log_data['Latency'] = 0
# Iterate over rows and extract latency
for r in range(log_data.shape[0]-1):
    if log_data.loc[r,'Event'] == 'EXP ' and log_data.loc[r+1,'Event'] == 'DATA ':
        log_data.loc[r,'Latency'] = log_data.loc[r+1,'Time'] - log_data.loc[r,'Time']
    
log_data = log_data[log_data['Event']=='EXP ']

# %%
plt.hist(log_data['Latency'])

# %%
