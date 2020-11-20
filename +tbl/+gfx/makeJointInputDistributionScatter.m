function jointFig = makeJointInputDistributionScatter(C)
%MAKEJOINTINPUTDISTRIBUTIONSCATTER Make joint scatter of input where x-axis is peak times and y-axis is peak spike rates
%
%  jointFig = tbl.gfx.makeJointInputDistributionScatter(C);
%
% Inputs
%  C - Table from `new_analysis.m`
% 
% Output
%  jointFig - Figure handle
%
% See also: Contents

jointFig = figure('Name','Distribution of Peak Times','Units','Normalized',...
   'Position',[0.132, 0.157, 0.5, 0.6],...
   'PaperOrientation','landscape','Color','w');
ax = axes(jointFig,'NextPlot','add','XColor','k','YColor','k','FontName','Arial');
scatter(ax,...
   C.peakTime(:)*1000,log(C.peakVal(:)),...
   'MarkerFaceColor','b','SizeData',4,...
   'MarkerEdgeColor','k','MarkerFaceAlpha',0.1,'MarkerEdgeAlpha',0.1);
xlabel(ax,'Peak Time (ms)','Color','k','FontName','Arial',...
   'FontName','Arial','FontSize',24);
ylabel(ax,'Peak Value (log(spikes/sec))','Color','k','FontName','Arial',...
   'FontName','Arial','FontSize',24);
title(ax,'Joint Distribution of Peaks and Times',...
   'FontName','Arial','Color','k','FontSize',24,'FontWeight','bold');

end