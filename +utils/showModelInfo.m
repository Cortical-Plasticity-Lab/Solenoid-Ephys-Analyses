function [covFig,resFig] = showModelInfo(mdl,tag)
%SHOWMODELINFO Print model info and optionally make figure for covariances
%
%  utils.showModelInfo(mdl);
%  fig = utils.showModelInfo(mdl,tag);
%
% Inputs
%  mdl - GLME model recovered using `fitglme`
%  tag - (Optional) string or char array to "tag" the figure/printed output
%
% Output
%  covFig - (Optional) If requested, generates a figure with covariance
%                       matrices for random effects (one matrix in
%                       panelized subplots per grouping).
%  resFig - (Optional) If requested, generates a figure with residuals for
%                       statistical models
%
% See also: Contents, run_stats.m

if nargin < 2
   tag = '';
end

fprintf(1,'\n--------------------------------------------\n');
fprintf(1,'\t\t\t<strong>%s</strong>\n',tag);
fprintf(1,'\n--------------------------------------------\n');

disp(mdl);

fprintf(1,'<strong>R-squared:</strong>\n');
disp(mdl.Rsquared);
disp(anova(mdl));

G = mdl.Formula.GroupingVariableNames;
N = numel(G);
gVar = cell(N,1);

allVals = [];
for iG = 1:N
   gVar{iG} = strjoin(mdl.Formula.GroupingVariableNames{iG},":"); 
   fprintf(1,'\nCovariance for Random Effects grouped by <strong>%s</strong>\n',gVar{iG});
   C = mdl.covarianceParameters{iG};
   allVals = [allVals; C(:)]; %#ok<AGROW>
   disp(C);
end

fprintf(1,'\n--------------------------------------------\n');

if nargout < 1
   return;
end

covFig = figure('Name',sprintf('Random Effects Covariance Parameters %s',tag),...
   'Color','w','Units','Normalized','Position',[0.15 0.15 0.80 0.55],...
   'PaperOrientation','Landscape','PaperSize',[8.5 11],...
   'PaperUnits','inches','PaperType','usletter','NumberTitle','off');
colormap('gray');

nRow = floor(sqrt(N));
nCol = ceil(sqrt(N));


for ii = 1:N
   ax = subplot(nRow,nCol,ii);
   rv = mdl.Formula.RELinearFormula{ii}.TermNames;
   set(ax,'NextPlot','add',...
      'Parent',covFig,'XColor','k','YColor','k','LineWidth',3,...
      'TickDir','out','FontName','Arial','FontSize',16,...
      'XTickLabelRotation',0,'YTickLabelRotation',90,...
      'XTick',1:numel(rv),'YTick',1:numel(rv),...
      'YDir','reverse','Box','on',...
      'XLim',[0.5 numel(rv)+0.5],'YLim',[0.5 numel(rv)+0.5],...
      'XTickLabel',mdl.Formula.RELinearFormula{ii}.TermNames,...
      'YTickLabel',mdl.Formula.RELinearFormula{ii}.TermNames,...
      'CLim',[0 max(allVals)]);
   imagesc(ax,1:numel(rv),1:numel(rv),mdl.covarianceParameters{ii});
   title(ax,gVar{ii},...
      'FontName','Arial','Color','k','FontSize',20,'FontWeight','bold');
   if ii == 1
      colorbar(ax,'Location','eastoutside');
   end
end

if nargout < 2
   return;
end

if size(get(groot,'MonitorPositions'),1) > 1
   pos = [1.027 0.132 0.8 0.55];
else
   pos = [0.15 0.15 0.80 0.55];
end

resFig = figure('Name',sprintf('Random Effects Covariance Parameters %s',tag),...
   'Color','w','Units','Normalized','Position',pos,...
   'PaperOrientation','Portrait','PaperSize',[8.5 11],...
   'PaperUnits','inches','PaperType','usletter','NumberTitle','off');
ax = axes(resFig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,'FontName','Arial');

tmp = figure;
h = plotResiduals(mdl,'fitted');
copyobj(h,ax);
delete(tmp);

end