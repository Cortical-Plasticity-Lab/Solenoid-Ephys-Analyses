function exFig = makeMultiPeakExamplePETH(C,iRow,xLim,yLim,P)
%MAKEMULTIPEAKEXAMPLEPETH Generate exemplar PETH to show multi-peaked nature of stimulus responses
%
%  exFig = tbl.gfx.makeMultiPeakExamplePETH(C);
%  exFig = tbl.gfx.makeMultiPeakExamplePETH(C,iRow,xLim,yLim,P);
%
% Inputs
%  C - Table from `new_analysis` after
%        `analyze.detectAverageEvokedSpikePeaks` has been applied.
%
%     OPTIONAL:
%  
%  iRow - Row index (scalar) to select the row from `C` to be used in the
%           exemplar figure.
%  xLim - Limits (milliseconds) of x-axis
%  yLim - Limits (spikes/sec) of y-axis
%  P    - Result from `P = tbl.peaks2rows(C);`
%
% Output
%  exFig - Figure handle
%
% See also: Contents, tbl, analyze, analyze.detectAverageEvokedSpikePeaks,
%                     run_analysis.m, run_stats.m

X_WINDOW_MS = [-100 300]; % milliseconds
Y_LIM_DEF = [-35 50];       % spikes/sec

if nargin < 2
   iRow = randi(size(C,1),1);
end

if nargin < 3
   xLim = X_WINDOW_MS;
end

if nargin < 4
   yLim = Y_LIM_DEF;
end

if nargin < 5
   P = tbl.peaks2rows(C);
end

exFig = figure('Name','Example Multi-Peak PETH',...
   'Color','w','Units','Normalized',...
   'Position',[0.491, 0.157, 0.300, 0.6],...
   'PaperOrientation','portrait');
ax = axes(exFig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
   'FontName','Arial','FontSize',16,'Box','on',...
   'XLim',xLim,'YLim',yLim,'XTick',[0 50 100 200]);
tEx = C.Properties.UserData.t.Spikes.*1000;
tIdx = tEx >= xLim(1) & tEx < xLim(2);

xRate = tEx(tIdx);
yRate = C.Smoothed_Mean_Spike_Rate(iRow,tIdx);

on = C.Solenoid_Onset(iRow)*1000;
off = C.Solenoid_Offset(iRow)*1000;
pY = [0 yLim(2)*0.75];
h = patch(ax,[on on off off],...
   pY([1,2,2,1]),...
   [0.6 0.2 0.2],...
   'FaceAlpha', 0.25,...
   'EdgeColor','none');
h.Annotation.LegendInformation.IconDisplayStyle = 'off';
on = C.ICMS_Onset(iRow)*1000;
if ~isinf(on)
   h = line(ax,[on on],[40 50],...
      'LineWidth',2.0,...
      'LineStyle','-',...
      'Color',[0.8 0 0.7],...
      'MarkerIndices',1,...
      'Marker','v',...
      'MarkerFaceColor',[0.8 0 0]);
   h.Annotation.LegendInformation.IconDisplayStyle = 'off';
end
h = line(ax,ax.XLim,ones(1,2).*C.Threshold(iRow),...
   'LineStyle','--','Color','m','LineWidth',2.5);
h.Annotation.LegendInformation.IconDisplayStyle = 'off';

% if isempty(C.Properties.RowNames)
%    C.Properties.RowNames = utils.parseRowNames(C);
% end
% dispName = C.Properties.RowNames{iRow};
dispName = utils.parseDataDescriptor(C,iRow);

line(ax,xRate,yRate,...
   'Color',[0 0 0],...
   'LineWidth',2.0,...
   'LineStyle','-',...
   'DisplayName',dispName);

p = P(P.ChannelID==C.ChannelID(iRow) & ...
      P.BlockID==C.BlockID(iRow) & ...
      string(P.Type)==string(C.Type(iRow)),:);
x = p.peakTime * 1000;
y = exp(p.peakVal);

hg = hggroup(ax,'DisplayName','Identified Peaks');
line(hg,x,y,'LineStyle','none',... % "outer bullseye"
   'Marker','o','MarkerSize',16,...
   'LineWidth',2.0,'MarkerEdgeColor','k');
line(hg,x,y,...
   'LineStyle','none',...
   'Marker','o',...
   'MarkerSize',8,...
   'LineWidth',1.5,...
   'MarkerEdgeColor','k',...
   'MarkerFaceColor','r');
if ~isempty(hg)
   hg.Annotation.LegendInformation.IconDisplayStyle = 'on';
end

xlabel(ax,'Time (ms)','FontName','Arial','Color','k','FontSize',24);
ylabel(ax,'E[spikes/s]','FontName','Arial','Color','k','FontSize',24);
title(ax,'Multi-Peak Example',...
   'FontName','Arial','Color','k','FontSize',24,'FontWeight','bold');
legend(ax,'TextColor','black','FontSize',16,'FontName','Arial',...
   'Color','w','EdgeColor','none','Location','south');
ax.YTick(ax.YTick < 0) = [];

end