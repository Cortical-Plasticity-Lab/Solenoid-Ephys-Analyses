function leg = addLegendToAxes(ax,params,varargin)
%ADDLEGENDTOAXES Add legend to axes depending on fields of params
%
%  leg = utils.addLegendToAxes(ax,params);
%  leg = utils.addLegendToAxes(ax,params,'Name',value,...);
%
% Inputs
%  ax       - Axes to add legend to
%  params   - Parameters struct that has fields 'Legend' and 'LegendParams'
%  varargin - (Optional) input arguments
%
% Output
%  leg      - Handle to legend object (or empty array [] if no object)
%
% See also: utils, tbl.gfx, tbl.gfx.PEP, tbl.gfx.PETH

if (nargin < 2) || isempty(params)
   params = cfg.gfx('Legend','LegendParams');
end

[varargin,params.Legend] = ...
   utils.parseNamedVariable(varargin,params.Legend,'Legend');
      
if strcmpi(params.Legend,'on')
   leg = legend(ax,'AutoUpdate','off',params.LegendParams{:},varargin{:});
else
   leg = [];
end
end