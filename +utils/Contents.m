% +UTILS Package with miscellaneous utility functions used in this pipeline
% MATLAB Version 9.2 (R2017a) 23-Jul-2020
%
%  Package with miscellaneous utility functions, some of which may be
%  deprecated.
%
% <strong>Graphics</strong>
%  addAreaToAxes   - Add label to axes indicating 'RFA' or 'S1' in a principled way
%  addLabelsToAxes - Add default labels to axes
%  addLegendToAxes - Add legend to axes depending on fields of params
%  addTextToAxes   - Add text to a specified location on an axes
%  addTypeToAxes   - Add label to axes indicating 'Solenoid (only)', 'ICMS (only)', or 'Solenoid+ICMS' in a principled way
%  checkXYLabels   - Check X-Y axes for correct labels at end of label strings
%  getFigAx        - Return figure and axes handles given parameters struct
%  parseTitle      - Parses title from filter input arguments
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