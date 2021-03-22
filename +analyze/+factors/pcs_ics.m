function [fig,ica_mdl,z, R] = pcs_ics(t,coeff,Y,tag)
%PCS_ICS Plot top-3 principal and independent components
%
%  fig = analyze.factors.pcs_ics(t,coeff,ica_mdl);

if nargin < 4
   tag = 'Solenoid';
end

[ica_mdl,z, R] = analyze.factors.getICs(Y,coeff);
fig = figure('Name','Solenoid PCs & ICs',...
   'Color','w','Units','Normalized','Position',[0.3 0.3 0.3 0.3]);
ax = subplot(2,1,1);
set(ax,'NextPlot','add','FontName','Arial','LineWidth',1);
plot(ax,t,coeff(:,1:3),'LineWidth',2);
title(ax,sprintf('%s: Top-3 PCs',tag),'FontName','Arial','Color','k');
xlabel(ax,'Time (sec)','FontName','Arial','Color','k');
ylabel(ax,'Coefficient','FontName','Arial','Color','k');

ax = subplot(2,1,2);
set(ax,'NextPlot','add','FontName','Arial','LineWidth',1);
plot(ax,t,ica_mdl.TransformWeights,'LineWidth',2);
title(ax,sprintf('%s: rICA (3 components)',tag),'FontName','Arial','Color','k');
xlabel(ax,'Time (sec)','FontName','Arial','Color','k');
ylabel(ax,'Coefficient','FontName','Arial','Color','k');

end