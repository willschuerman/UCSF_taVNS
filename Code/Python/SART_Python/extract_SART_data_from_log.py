#%%
import os
import glob
cur_dir = os.getcwd()
data_dir = cur_dir.replace('Code/Python/SART_Python','Data/SART_Microstudy')
# %%
# get list of log files
file_list = glob.glob(data_dir + '/*.log')
# %%
# read in first log file line by line
# Using readlines()
log_file = open(file_list[0], 'r')
log_lines = log_file.readlines()
# %%
