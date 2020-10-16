% +TBL  Package with sub-packages and functions for handling table exported using solRat.makeTables
% MATLAB Version 9.7 (R2019b Update 5) 15-Jun-2020
%
%  Contains packages for generating graphics and running statistics on data
%  in table format.
%
% Packages
%  est                  - Package with small functions for estimating responses using `splitapply` workflow
%  gfx                  - Package with figure export/generation functions
%  stats                - Package with statistics export or analysis functions
%
% Functions
%  addLaminarCategories - Adds categorical variable `Lamina` based on depth/area
%  addTrialLFPtMin      - Add LFP time-to-min as variable to main data table
%  addProcessing        - Add 'Processing' field to UserData struct table property or append to existing 'Processing' list
%  addSlicing           - Add 'Slicing' field to UserData struct table property or append to existing 'Slicing' list
%  parseProbeData       - Parse data about probes from file Probe-info.xlsx
%  parseBlockID         - Parse block ID metadata as variables
%  slice                - Return "sliced" table using filters in `varargin`
%  elimCh            - Remove channels with low spiking activity 
%  excludeIpsi       - Exclude trials from dataset on the ipsilateral side
%  addSlicing           - Add 'Slicing' field to UserData struct table property or append to existing 'Slicing' list
%  addProcessing        - Add 'Processing' field to UserData struct table property or append to existing 'Processing' list
%  addLaminarCategories - Adds categorical variable `Lamina` based on depth/area