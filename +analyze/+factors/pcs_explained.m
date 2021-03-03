function fig = pcs_explained(explained,tag)
%PCS_EXPLAINED Return figure for % explained by PC
%
%  fig = analyze.factors.pcs_explained(explained);

if nargin < 2
   tag = 'Solenoid';
end

fig = figure('Name',sprintf('Principal Components: %s',tag),...
   'Color','w','Units','Normalized','Position',[0.3 0.3 0.3 0.3]);
ax = axes(fig,'NextPlot','add','FontName','Arial','LineWidth',1);
cEx = cumsum(explained);
plot(ax,0:numel(explained),[0;cEx],'LineWidth',2,'Color','k');
line(ax,[3 3],[0 cEx(3)],'LineWidth',2,'Color','b','LineStyle',':','Marker','o','MarkerIndices',2);
line(ax,[0 3],[cEx(3) cEx(3)],'LineWidth',2,'Color','b','LineStyle',':');
text(ax,3,cEx(3)+10,sprintf('%4.1f%%',cEx(3)),'FontName','Arial','Color','b','FontWeight','bold');
title(ax,sprintf('%s PCs: % Explained',tag),'FontName','Arial','Color','k');
xlabel(ax,'PC Index','FontName','Arial','Color','k');
ylabel(ax,'% Explained','FontName','Arial','Color','k');

end