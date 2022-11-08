# UCSF_taVNS
Information and code for conducting and analyzing taVNS experiments.

This repository contains code for running taVNS experiments using Matlab and Python, as well as analysis code in Matlab, Python, and R. 
- The Matlab code is easily editable for creating simple, custom experiments and doing testing (equipment, thresholds, etc...)
- The Python code utilizes Psychopy for generating more complex experiments combining taVNS with tasks and audio/visual stimuli. 
- The R code is useful for swiftly reading in data and generating plots and effect size estimates.

The repository also contains information on
- The equipment utilized by the UCSF Chang Lab to carry out taVNS experiments. 
- Procedures for preparing participants for taVNS studies. 
- Safety information, primarily in the form of checklists, for both researchers and participants. 

The repository is divided into the following sections:
- Information
- Code
    - Matlab
        - Stimulation
        - Analysis
        - Experiments
    - Python
        - Python_analysis (code for plotting data from physio experiments)
        - Python_taVNS (code for running simple, custom experiments with PsychoPy)
        - SART_Python (Sustained Attention Response Task)
    - R
        - R_analysis (code for analyzing and plotting data from physio/SART experiments)