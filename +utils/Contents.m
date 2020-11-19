% +UTILS Package with miscellaneous utility functions used in this pipeline
% MATLAB Version 9.2 (R2017a) 23-Jul-2020
%
%  Package with miscellaneous utility functions, some of which may be
%  deprecated.
%
% <strong>Graphics</strong>
%  addAreaToAxes                       - Add label to axes indicating 'RFA' or 'S1' in a principled way
%  addConnectingLine                   - Add (annotated) line connecting point pairs <X,Y>
%  addLabelsToAxes                     - Add default labels to axes
%  addLegendToAxes                     - Add legend to axes depending on fields of params
%  addPeakLabels                       - Add labels denoting <x,y> value at list of peaks
%  addSolenoidToAxes                   - Add indicator of solenoid strike to axes
%  addStimInfoToAxes                   - Add information about stimulus-type, timing, and if ICMS occurred on this channel.
%  addTextToAxes                       - Add text to a specified location on an axes
%  addTimeIndicatorToAxes              - Add graphics indicator for some event to an axes
%  addTypeToAxes                       - Add label to axes indicating 'Solenoid (only)', 'ICMS (only)', or 'Solenoid+ICMS' in a principled way
%  checkXYLabels                       - Check X-Y axes for correct labels at end of label strings
%  expAI                               - Export figure in appropriate format for Adobe Illustrator
%  exportSaveFigure                    - Export and save figures using Figures.PlotGroupedResponses
%  formatDefaultAxes                   - Apply default axes settings preferred by MM
%  formatDefaultFigure                 - Apply default figure settings preferred by MM
%  formatDefaultLabel                  - Apply default font settings preferred by MM
%  getFigAx                            - Return figure and axes handles given parameters struct
%  parseTitle                          - Parses title from filter input arguments
%  plotCoherence                       - Helper function to plot coherence (from example R2017a)
%  plotSpikeRaster                     - Create raster plot from binary spike data or spike times
%
% <strong>Functions</strong>
%  computeSmoothMeanSpikeRate          - Compute smoothed average spike rate from individual trial observations
%  fastsmooth                          - Smooths vector X
%  findStims                           - Return stimulation indices based on all STIM files
%  findUniqueEventCombinations         - Return or print table of unique event combinations
%  getCB95                             - Return 95% confidence bounds
%  getFactors_Batch                    - Return NNMF Factors in batch for several combinations of number of factors
%  getNeuralStatePCs                   - Return PCA data for neural state by concatenating trials
%  getNormDepth                        - Return "normalized" depth based on laminar groupings
%  getOpt                              - Process paired optional arguments as `prop`,val1 
%  getPathTo                           - Return output from uigetdir basically
%  getPCs                              - Return principal components for response variable in data
%  HPF                                 - Software estimate of hardware single-pole state high-pass filter
%  makeKey                             - Utility to make random alphanumeric key-string for naming a "row"
%  parseNamedVariable                  - Parse optional inputs and update a named variable
%  pivotRows                           - Pivot rows of each corresponding variable in `T1` to produce `T2`
%  reduceData                          - Return reduced table version
%  roundEventTimesToNearestMillisecond - Set ICMS onset/offset and Solenoid onset/offset to nearest millisecond value (as seconds)
%  sec2string                          - Take seconds (double) and return time string for hours, minutes, and seconds