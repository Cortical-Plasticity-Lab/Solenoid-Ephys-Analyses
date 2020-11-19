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

% Organize (rank) the columns by peak value
nRow = size(C,1); 
nCol = size(C.peakVal,2);
[C.peakVal,pkIdx] = sort(C.peakVal,2,'descend','MissingPlacement','last');
pkIdx = mat2cell(pkIdx,ones(1,nRow),nCol);
C.peakTime = mat2cell(C.peakTime,ones(1,nRow),nCol);
C.peakTime = cell2mat(...
   cellfun(@(tPk,iVal)tPk(iVal),C.peakTime,pkIdx,'UniformOutput',false));

% Now, export them so that each array element gets its own row
P = utils.pivotRows(C,'peakVal','peakTime');
P(isnan(P.peakVal),:) = [];
P.peakVal = log(P.peakVal);
P.Properties.VariableNames{'Array_Column'} = 'peakRank';
P.Properties.VariableUnits{'peakVal'} = 'log(spikes/s)';
P.Properties.VariableUnits{'peakTime'} = 's';

if nargout < 2
   return;
end

swarmFig = figure('Name','Boxplot of Peak Values by Rank',...
   'Color','w','Units','Normalized','Position',[0.3 0.15 0.3 0.6],...
   'PaperOrientation','landscape');
ax = axes(swarmFig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
   'FontName','Arial','FontSize',16,'CLim',[0 0.225],'Box','off',...
   'XTick',1:nCol);
swarmchart(ax,P.peakRank,P.peakVal,14,...
   P.peakTime - P.Solenoid_Onset__Exp,...
   'MarkerFaceAlpha',0.35,...
   'MarkerFaceColor','flat',...
   'MarkerEdgeColor','none');
xlabel(ax,'Rank','FontName','Arial','Color','k','FontSize',24);
ylabel(ax,'log(spikes/s)','FontName','Arial','Color','k','FontSize',24);
title(ax,'Ranked Peak Values','FontName','Arial','Color','k','FontSize',24,'FontWeight','bold');
colorbar(ax,'Location','north','Ticks',[0.035 0.190],...
   'TickLabels',{'Solenoid: Early','Solenoid: Late'},...
   'AxisLocation','in');

if nargout < 3
   return;
end

EXAMPLE_INDEX_DEF = 28;   % index
X_WINDOW_MS = [-100 300]; % milliseconds
Y_LIM_DEF = [0 50];       % spikes/sec
if nargin < 3
   exampleRowIndex = EXAMPLE_INDEX_DEF; % if not provided in function call
end
iRow = exampleRowIndex;
exFig = figure('Name','Example Multi-Peak PETH',...
   'Color','w','Units','Normalized','Position',[0.3 0.15 0.3 0.6],...
   'PaperOrientation','landscape');
ax = axes(exFig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
   'FontName','Arial','FontSize',16,'Box','on',...
   'XLim',X_WINDOW_MS,'YLim',Y_LIM_DEF);
tEx = C.Properties.UserData.t.Spikes.*1000;
tIdx = tEx >= X_WINDOW_MS(1) & tEx < X_WINDOW_MS(2);
on = C.Solenoid_Onset(iRow)*1000;
off = C.Solenoid_Offset(iRow)*1000;
patch(ax,[on on off off],[-30 40 40 -30],...
   [0.6 0.2 0.2],...
   'FaceAlpha', 0.25,...
   'EdgeColor','none',...
   'DisplayName','Solenoid Strike');
on = C.ICMS_Onset(iRow)*1000;
if ~isinf(on)
   line(ax,[on on],[40 50],...
      'LineWidth',2.0,...
      'LineStyle','-',...
      'DisplayName','ICMS',...
      'Color',[0.8 0 0.7],...
      'MarkerIndices',1,...
      'Marker','v',...
      'MarkerFaceColor',[0.8 0 0]);
end
line(ax,...
   tEx(tIdx),...
   C.Smoothed_Mean_Spike_Rate(iRow,tIdx),...
   'Color',[0 0 0],...
   'LineWidth',2.0,...
   'LineStyle','-',...
   'DisplayName',C.Properties.RowNames{iRow});

p = P(P.ChannelID==C.ChannelID(iRow) & ...
      P.BlockID==C.BlockID(iRow) & ...
      string(P.Type)==string(C.Type(iRow)),:);
x = p.peakTime * 1000;
y = exp(p.peakVal);

line(ax,x,y,'LineStyle','none','Marker','o','MarkerSize',16,...
   'LineWidth',1.5,'MarkerEdgeColor','b','DisplayName','Identified Peaks');

xlabel(ax,'Time (ms)','FontName','Arial','Color','k','FontSize',24);
ylabel(ax,'E[spikes/s]','FontName','Arial','Color','k','FontSize',24);
title(ax,'Multi-Peak Example',...
   'FontName','Arial','Color','k','FontSize',24,'FontWeight','bold');
legend(ax,'TextColor','black','FontSize',16,'FontName','Arial',...
   'Color','w','EdgeColor','none','Location','northeast');

end