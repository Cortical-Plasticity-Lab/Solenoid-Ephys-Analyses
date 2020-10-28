% SOLENOID-EPHYS-ANALYSES  All Matlab code for acute solenoid evoked sensory stimuli + ICMS experiments
% MATLAB Version 9.2 (R2017a) 23-July-2020
%
%  Analytical workflow:
%  0. Apply pre-processing and spike detection (see: CPLtools sub-folders
%        MoveData_Isilon and _SD in github repos of m053m716). 
%        For more details about this process, read:
%         + Bundy DT, Guggenmos DJ, Murphy MD, Nudo RJ. 
%              Chronic stability of single-channel neurophysiological 
%              correlates of gross and fine reaching movements in the rat. 
%              PLoS One. 2019;14(10):e0219034. Published 2019 Oct 30. 
%              doi:10.1371/journal.pone.0219034
%  1. Aggregate extracted data and metadata using object-oriented
%        hierarchical structure: from lowest (most-granular) to highest,
%        this is ordered as:
%        * @solChannel
%        * @solBlock
%        * @solRat
%  2. Export master table with primary response data stored in `.Spikes`
%        and `.LFP` variables, which is then used in combination with
%        sub-packages of `+analyze/+[package]` to address corresponding
%        points in the paper.
%
%  For a rough "concrete" overview of the workflow, see outline in script
%  `main.m`; certain parts are commented because they might take a long
%  time or were slightly different when run on different machines
%  (particularly during the initial COVID-19 quarantine phase).
%
% <strong>Scripts</strong>
%   main.m                             - General overview and main outline of workflow (after pre-processing)
%   batch_Fig3                         - Batch script to run code associated with generating Figure 3
%
% <strong>Functions</strong>
%   batch_view_reaching_performances   - Import/plot behavior data for all animals from spreadsheet  
%
% <strong>Classes</strong>
%   @figBrowser                        - If figures are exported as .png/.fig for example using batchProbePETH method of solRat or solBlock, this can be used to view
%   @solChannel                        - Handle class to organize data at the individual-channel level
%   @solBlock                          - Handle class for organizing data from an individual recording
%   @solRat                            - Handle class to organize data collected for all animal recordings
%
% <strong>Sub-Packages</strong>
%   Fig3                               - Package for tools used in Figure 3
%   analyze                            - Analyses for endpoints related to positive or negative controls, such as testing for evoked sensory activity on solenoid stimuli in FL-S1
%   cfg                                - Package containing any default configuration parameters
%   tbl                                - Package with sub-packages and functions for handling table exported using solRat.makeTables
