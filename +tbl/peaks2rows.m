function [P,swarmFig,exFig] = peaks2rows(C,exampleRowIndex)
%PEAKS2ROWS Convert arrays of peak times and values to individual rows for each channel
%
%  P = tbl.peaks2rows(C);
%  [P,swarmFig] = tbl.peaks2rows(C);
%  [P,swarmFig,exFig] = tbl.peaks2rows(C,exampleRowIndex);
%
% Inputs
%  C               - Table from `new_analysis.m` used in `run_stats.m`
%  exampleRowIndex - (Default: EXAMPLE_INDEX_DEF in code below)
%                    -> works together with `exFig` optional third
%                       output argument to select which channel/block/type
%                       mean that we want to plot for the example.
%
% Output
%  P - Same data table, but with NaN rows excluded and with peakTime and
%        peakVal variables "pivoted."
%  swarmFig - (Optional) if specified, return swarm scatter 
%                    with y-axis reflecting the log spike rate of
%                    individual peaks for a given peak ranked by its
%                    amplitude compared to other peaks in the same
%                    channel/block combination (x-axis).
%  exFig    - (Optional) if specified, return example figure that shows a
%                          case where there are multiple spike rate peaks
%                          in the peri-event time histogram.
%
% See also: tbl, run_stats.m, new_analysis.m

% Constants for if figures are to be generated:
X_WINDOW_MS = [-100 300];  % milliseconds
Y_LIM_DEF = [-20 50];      % spikes/sec
EXAMPLE_INDEX_DEF = 28;    % index of the row (channel/type/block combo)

% Organize (rank) the columns by peak value
nCol = size(C.peakVal,2);

% Now, export them so that each array element gets its own row
P = utils.pivotRows(C,'peakVal','peakTime');
P(isnan(P.peakVal),:) = [];
P.peakVal = log(P.peakVal);
P.Properties.VariableNames{'Array_Column'} = 'peakRank';
P.Properties.VariableUnits{'peakVal'} = 'log(spikes/s)';
P.Properties.VariableUnits{'peakTime'} = 's';

switch nargout
   case {0,1}
      return;
   case 2
      swarmFig = tbl.gfx.makePeakRankScatter(P,"Solenoid",nCol);
   case 3
      if nargin < 3
         exampleRowIndex = EXAMPLE_INDEX_DEF; % if not provided in function call
      end
      iHighlight = P.ChannelID==C.ChannelID(exampleRowIndex) & ...
         string(P.Type)==string(C.Type(exampleRowIndex)) & ...
         string(P.BlockID)==string(C.BlockID(exampleRowIndex));
      swarmFig = tbl.gfx.makePeakRankScatter(P,"Solenoid",nCol,iHighlight);
      exFig = tbl.gfx.makeMultiPeakExamplePETH(...
         C,...
         exampleRowIndex,...
         X_WINDOW_MS,...
         Y_LIM_DEF,...
         P);
   otherwise
      error('Invalid number of output arguments requested (max. is 3)');
      
end

end