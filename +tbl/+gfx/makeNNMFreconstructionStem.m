function fig = makeNNMFreconstructionStem(C,D,f,tag,hl)
%MAKENNMFRECONSTRUCTIONSTEM  Make stem plot of NNMF reconstruction accuracy
%
%  fig = tbl.gfx.makeNNMFreconstructionStem(C,D,f);
%
% Inputs
%  C - Channel-average table with spikes averages
%  D - Reconstruction error vector
%  f - Number of factors corresponding to elements of D
%
% Output
%  fig - Figure handle. If not requested, automatically saves and deletes
%        the output figure.
%
% See also: Contents, tbl, tbl.gfx, tbl.gfx.plotNNMFfactors

if nargin < 4
   tag = '';
end

if nargin < 5
   hl = [];
end

MU = mean(C.Spikes,2)';
SE = (C.Spikes' - MU).^2;
RMSE = sqrt(mean(mean(SE)));
fig = figure('Color','w','Name','Non-Negative Spikes Factors'); 
ax = axes(fig,'XColor','k','YColor','k','YLim',[0 1],...
   'NextPlot','add','FontName','Arial','LineWidth',1.5);
stem(ax,f(1),1-D(1)./RMSE,'Color','k','LineWidth',2);
vec = 2:(numel(f)-1);
stem(ax,f(setdiff(vec,hl)),1-D(setdiff(vec,hl))./RMSE,...
   'Color',[0.35 0.35 0.35],'LineWidth',1.5); 
stem(ax,f(end),1-D(end)./RMSE,'Color','k','LineWidth',2);
for ii = 1:numel(hl)
   stem(ax,f(hl(ii)),1-D(hl(ii))./RMSE,...
      'Color',[1.0 0.2 0.2],...
      'LineWidth',2.5);
end

xlabel(ax,'Number Factors','FontName','Arial','Color','black');
ylabel(ax,'R^2','FontName','Arial','Color','black');
if isempty(tag)
   title(ax,'Factor Reconstruction Accuracy','FontName','Arial','Color','black');
else
   title(ax,sprintf('Factor Reconstruction Accuracy (%s)',strrep(tag,'_','')),...
      'FontName','Arial','Color','black');
end

if nargout < 1
   if exist('figures/NNMF','dir')==0
      mkdir('figures/NNMF');
   end
   saveas(fig,['figures/NNMF/NNMF-Spikes-Reconstruction-Accuracy' tag '.png']);
   savefig(fig,['figures/NNMF/NNMF-Spikes-Reconstruction-Accuracy' tag '.fig']);
   delete(fig);
end

end