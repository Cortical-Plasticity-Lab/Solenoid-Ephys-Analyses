function histFig = makeSpikePeakLatencyHistogram(C)
%MAKESPIKEPEAKLATENCYHISTOGRAM Generate histogram of spike peak latencies
%
%  histFig = tbl.gfx.makeSpikePeakLatencyHistogram(C);
%
% Inputs
%  C - Data table from `new_analysis.m` with spike peaks detected
%
% Output
%  histFig - Figure handle
%
% See also: Contents, analyze, analyze.detectAverageEvokedSpikePeaks,
%                     new_analysis.m

if size(get(groot,'MonitorPositions'),1) > 1
   pos = [1.11 0.12 0.50 0.50];
else
   pos = [0.487 0.361 0.489 0.539];
end

histFig = figure('Name','Distribution of Peak Times','Color','w',...
   'Units','Normalized','Position',pos,...
   'PaperOrientation','landscape');
ax = axes(histFig,'NextPlot','add','XColor','k','YColor','k','FontName','Arial');
histogram(ax,C.peakTime*1000,0:5:300);
set(get(ax,'Children'),'FaceColor','k','EdgeColor','none','DisplayName',...
   'Spike Peak Onset Data');
xlabel(ax,'Time (ms)','Color','k','FontName','Arial',...
   'FontName','Arial','FontSize',24);
ylabel(ax,'Count (channels/block/type)','Color','k',...
   'FontName','Arial','FontSize',24);
title(ax,'Distribution of Evoked Spike Peak times (all types)',...
   'FontName','Arial','Color','k','FontSize',24,'FontWeight','bold');

end