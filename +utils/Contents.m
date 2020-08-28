% +UTILS Package with miscellaneous utility functions used in this pipeline
% MATLAB Version 9.2 (R2017a) 23-Jul-2020
%
%  Package with miscellaneous utility functions, some of which may be
%  deprecated.
%
% <strong>Graphics</strong>
%  addLabelsToAxes - Add default labels to axes
%  checkXYLabels   - Check X-Y axes for correct labels at end of label strings
%  getFigAx        - Return figure and axes handles given parameters struct
%  plotCoherence   - Helper function to plot coherence (from example R2017a)
%  plotSpikeRaster - Create raster plot from binary spike data or spike times
%
% <strong>Functions</strong>
%  fastsmooth      - Smooths vector X
%  getCB95         - Return 95% confidence bounds
%  getOpt          - Process paired optional arguments as `prop`,val1 
%  getPathTo       - Return output from uigetdir basically
%  makeKey         - Utility to make random alphanumeric key-string for naming a "row"
%  sec2string      - Take seconds (double) and return time string for hours, minutes, and seconds