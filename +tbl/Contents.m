% +TBL  Package with sub-packages and functions for handling table exported using solRat.makeTables
% MATLAB Version 9.7 (R2019b Update 5) 15-Jun-2020
%
%  Contains packages for generating graphics and running statistics on data
%  in table format.
%
% Packages
%   est                           - Package with small functions for estimating responses using `splitapply` workflow
%   gfx                           - Package with figure export/generation functions
%   stats                         - Package with statistics export or analysis functions
%
% Functions
%   addExperimentOnsetOffsetTimes - Parses ICMS_Onset, Solenoid_Onset, Solenoid_Offset, and Type to append unified stimulus times
%   addLaminarCategories          - Adds categorical variable `Lamina` based on depth/area
%   addLV                         - Add lesion volume information to main table
%   addTrialLFPtMin               - Add LFP time-to-min as variable to main data table
%   addProcessing                 - Add 'Processing' field to UserData struct table property or append to existing 'Processing' list
%   addSlicing                    - Add 'Slicing' field to UserData struct table property or append to existing 'Slicing' list
%   parseProbeData                - Parse data about probes from file Probe-info.xlsx
%   parseBlockID                  - Parse block ID metadata as variables
%   slice                         - Return "sliced" table using filters in `varargin`
%   elimCh                        - Eliminate channels from blocks with low spiking 
%   excludeBlocks                 - Exclude blocks from dataset 
%   addSlicing                    - Add 'Slicing' field to UserData struct table property or append to existing 'Slicing' list
%   addProcessing                 - Add 'Processing' field to UserData struct table property or append to existing 'Processing' list
%   addLaminarCategories          - Adds categorical variable `Lamina` based on depth/area
%   addStimLamina                 - Add Laminar classification of ICMS stimulation channel
%   addVarMaxMinTime              - Add LFP variance time-to-min as variable to main data table
%   formatDataTable               - Get data table into correct format with largest grouping variables on the left, and dependent variables on the right
%   getTopPCscores                - Return table with top-K principal component scores
