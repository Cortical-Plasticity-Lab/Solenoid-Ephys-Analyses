% +ANALYZE Package for analyses of solenoid acute experimental data
% MATLAB Version 9.2 (R2017a) 23-July-2020
%
%  This package contains sub-packages for different phases of experimental
%  analysis, which should roughly correspond to the different results
%  described in the paper.
%
% <strong>Sub-Packages</strong>
%   control                   - Analyses for endpoints related to positive or negative controls, such as testing for evoked sensory activity on solenoid stimuli in FL-S1
%   rat                       - Package for analyses of single-rat data
%
% <strong>Functions</strong>
%   assignBasalThreshold      - Return table where rows are average spikes/channel
%   detectAverageEvokedPeaks  - Detect peaks in condition-averaged evoked activity on per-channel, per-block basis
%   perObservationThreshold   - Create table of per-observation thresholds