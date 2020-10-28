function fig = plotNNMFfactors(t,W,tag)
%PLOTNNMFFACTORS Plot time-weighting factors for a given number of NNMF
%
%  fig = tbl.gfx.plotNNMFfactors(t,W);
%
% Inputs
%  t - Times of each sample (corresponding to time-factor weights; seconds)
%  W - Matrix of factors to plot
%
% Output
%  fig - Figure handle. If not requested, automatically saves and deletes
%        the output figure.
%
% See also: Contents, tbl, tbl.gfx, tbl.gfx.makeNNMFreconstructionStem

if nargin < 3
   tag = '';
end

fig = figure('Color','w','Name','NNMF Spikes');
ax = axes(fig,'XColor','k','YColor','k',...
   'NextPlot','add','FontName','Arial','LineWidth',1.5,...
   'XLim',[0 150]);
plot(ax,t.*1e3,W,'LineWidth',1.5);
xlabel(ax,'Time (ms)','FontName','Arial','Color','black');
ylabel(ax,'Factor Weighting','FontName','Arial','Color','black');

if isempty(tag)
   title(ax,sprintf('Spikes NNMF (N = %d)',size(W,2)),'FontName','Arial','Color','black');
else
   title(ax,sprintf('Spikes NNMF (N = %d | %s)',size(W,2),strrep(tag,'_','')),...
      'FontName','Arial','Color','black');
end
strOpts = [...
   string(sprintf('Spikes NNMF (N = %d)',size(W,2))),  ...
   string(sprintf('Spikes NNMF (N = %d | %%s)',size(W,2))) ...
   ];
tagStr = io.appendTag(tag,strOpts);
title(ax,tagStr,'FontName','Arial','Color','black');

if nargout < 1   
   io.optSaveFig(fig,fullfile(pwd,'figures/NNMF'),...
      sprintf('NNMF-Spikes-Factors-N_%d',size(W,2)),tag);
end

end