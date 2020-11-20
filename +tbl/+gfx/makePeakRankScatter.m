function [swarmFig,s] = makePeakRankScatter(P,nCol,iHighlight)
%MAKEPEAKRANKSCATTER Generate scatter with x-axis of peak rank and y-axis of peak value (log-transformed spike rate). 
%
%  swarmFig = tbl.gfx.makePeakRankScatter(P);
%  [swarmFig,s] = tbl.gfx.makePeakRankScatter(P,nCol,iHighlight);
%
% Inputs
%  P - Results from `tbl.peak2rows` on `peakTime` and `peakVal` from `C` in
%        `new_analysis.m`
%
%     OPTIONAL:
%
%  nCol - Number of columns (if not specified, uses max value from
%           `P.peakRank`)
%  iHighlight - Indices of scatter points to "highlight"
%
% Output
%  swarmFig - Figure handle
%  s        - Swarm scatter object
%
% See also: Contents, tbl, new_analysis.m, tbl.peak2rows

if nargin < 2
   nCol = max(P.peakRank);
end

if nargin < 3
   iHighlight = [];
end
   
swarmFig = figure('Name','Boxplot of Peak Values by Rank',...
   'Color','w','Units','Normalized',...
   'Position',[0.132, 0.157, 0.300, 0.6],...
   'PaperOrientation','portrait');
ax = axes(swarmFig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
   'FontName','Arial','FontSize',16,'CLim',[0 0.225],'Box','off',...
   'XTick',1:nCol,'XLim',[0.5 nCol+0.5],'YLim',[0 8]);
colormap(ax,'parula');
s = swarmchart(ax,P.peakRank,P.peakVal,10,...
   P.peakTime - P.Solenoid_Onset__Exp,'filled',...
   'MarkerFaceAlpha',0.35);
xlabel(ax,'Peak Rank (by amplitude)','FontName','Arial','Color','k','FontSize',24);
ylabel(ax,'log(spikes/s)','FontName','Arial','Color','k','FontSize',24);
title(ax,'Ranked Peak Values','FontName','Arial','Color','k','FontSize',24,'FontWeight','bold');
colorbar(ax,'Location','north','Ticks',[0.035 0.190],...
   'TickLabels',{'Solenoid: Early','Solenoid: Late'},...
   'AxisLocation','in');

if isempty(iHighlight)
   return;
end

x = s.XData(iHighlight);
y = s.YData(iHighlight);
scatter(ax,x,y,40,[0 0 0],'Marker','o','MarkerFaceColor','none','MarkerEdgeColor','flat');
scatter(ax,x,y,30,[0 0 0],'Marker','o','MarkerFaceColor','r','MarkerEdgeColor','flat');

end