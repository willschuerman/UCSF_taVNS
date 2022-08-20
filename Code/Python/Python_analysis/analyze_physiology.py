#%%
import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import seaborn as sns

#%% 
%matplotlib qt
# Move to Data directory

os.chdir('../../..')
os.chdir('Data')
#%%
filename = 'tVNS_Li_HRV analysis.xlsx'


# %%
data = pd.read_excel('Physiology_Tests/'+filename,sheet_name='HRV Stats',nrows=26,index_col=0).transpose()
data['Block'] = pd.Series()
data.loc[data.index<6,'Block'] = 'Baseline'
data.loc[(data.index>5) & (data.index<11),'Block'] = 'Stim1'
data.loc[(data.index>10) & (data.index<16),'Block'] = 'Washout1'
data.loc[(data.index>15) & (data.index<21),'Block'] = 'Stim2'
data.loc[(data.index>20) & (data.index<26),'Block'] = 'Washout2'
data.loc[(data.index>25) & (data.index<31),'Block'] = 'Stim3'

data['BlockType'] = pd.Series()
data.loc[data.index<6,'BlockType'] = 'Rest'
data.loc[(data.index>5) & (data.index<11),'BlockType'] = 'Stim'
data.loc[(data.index>10) & (data.index<16),'BlockType'] = 'Rest'
data.loc[(data.index>15) & (data.index<21),'BlockType'] = 'Stim'
data.loc[(data.index>20) & (data.index<26),'BlockType'] = 'Rest'
data.loc[(data.index>25) & (data.index<31),'BlockType'] = 'Stim'
# %%
datamelt = data[['Mean Heart Rate','RSA','Mean IBI','SDNN','RMSSD','NN50','pNN50','Block','BlockType']].melt(id_vars=['Block','BlockType'])
# %%
datamelt['Variable'] = datamelt['Segment Number']
sns.catplot(
    data=datamelt, x='Block', y='value',
    col='Variable', kind='box', col_wrap=3,sharey=False,
    palette = ['b','r','b','r','b','r']
)

# %%
data = pd.read_excel('Physiology_Tests/'+filename,sheet_name='Power Band Stats')

# %%
datamat = np.array(data.drop(columns='Segment Number')).T
datamat_labels = data['Segment Number'].values
# %%
fig,ax = plt.subplots(nrows = 3, ncols=3)
counter = 0
for r in range(3):
    for c in range(3):
        if counter < 7:
            ax[r,c].plot(datamat[:,counter])
            ax[r,c].hlines(np.min(datamat[:,counter]),xmin=5,xmax=10,color='r')
            ax[r,c].hlines(np.min(datamat[:,counter]),xmin=15,xmax=20,color='r')
            ax[r,c].hlines(np.min(datamat[:,counter]),xmin=25,xmax=30,color='r')
            ax[r,c].title.set_text(datamat_labels[counter])
            counter+=1
fig.suptitle('Power Band Metrics')

# %%
data = pd.read_excel('Physiology_Tests/'+filename,sheet_name='Power Band Stats',index_col=0).transpose()

# %%
data['Block'] = pd.Series()
data.loc[data.index<6,'Block'] = 'Baseline'
data.loc[(data.index>5) & (data.index<11),'Block'] = 'Stim1'
data.loc[(data.index>10) & (data.index<16),'Block'] = 'Washout1'
data.loc[(data.index>15) & (data.index<21),'Block'] = 'Stim2'
data.loc[(data.index>20) & (data.index<26),'Block'] = 'Washout2'
data.loc[(data.index>25) & (data.index<31),'Block'] = 'Stim3'

data['BlockType'] = pd.Series()
data.loc[data.index<6,'BlockType'] = 'Rest'
data.loc[(data.index>5) & (data.index<11),'BlockType'] = 'Stim'
data.loc[(data.index>10) & (data.index<16),'BlockType'] = 'Rest'
data.loc[(data.index>15) & (data.index<21),'BlockType'] = 'Stim'
data.loc[(data.index>20) & (data.index<26),'BlockType'] = 'Rest'
data.loc[(data.index>25) & (data.index<31),'BlockType'] = 'Stim'


# %%
datamelt = data.melt(id_vars=['Block','BlockType'])
datamelt['Variable'] = datamelt['Segment Number']
sns.catplot(
    data=datamelt, x='Block', y='value',
    col='Variable', kind='box', col_wrap=3,sharey=False,
    palette = ['b','r','b','r','b','r']
)
# %%
