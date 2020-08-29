function addLabelsToAxes(ax,params)
%ADDLABELSTOAXES Add default labels to axes
%
%  utils.addLabelsToAxes(ax,params);
%
% Inputs
%  ax       - Axes handle
%  params   - Parameters struct containing 'XLabel','YLabel','Title', and
%                 'FontParams' fields
%
% Output
%  -- none --
%
% Updates the label and title objects associated with axes `ax`
%
% See also: utils, tbl.gfx, tbl.gfx.PEP, tbl.gfx.PETH

xlabel(ax,params.XLabel,params.FontParams{:});
ylabel(ax,params.YLabel,params.FontParams{:});
title(ax,params.Title,params.FontParams{:});

if ~isempty(params.XLim)
   set(ax,'XLim',params.XLim);
end
if ~isempty(params.YLim)
   set(ax,'YLim',params.YLim);
end

end