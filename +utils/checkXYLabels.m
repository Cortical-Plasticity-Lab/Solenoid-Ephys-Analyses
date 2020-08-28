function params = checkXYLabels(params,unitsX,unitsY)
%CHECKXYLABELS Check X-Y axes for correct labels at end of label strings
%
%  params = utils.checkXYLabels(params,unitsX,unitsY);
%
% Inputs
%  params - Parameters struct with 'XLabel' and 'YLabel' fields
%  unitsX - Char array or string to check for at end of 'XLabel' string
%           -> e.g. '(ms)'
%  unitsY - Char array or string to check for at end of 'YLabel' string
%           -> e.g. '(Spikes/sec)'
%
% Output
%  params - Updated parameters struct with corrected label string fields
%
% See also: utils, tbl.gfx, tbl.gfx.PEP, tbl.gfx.PETH

if ~endsWith(params.XLabel,unitsX)
   params.XLabel = sprintf('%s %s',params.XLabel,unitsX);
end
if ~endsWith(params.YLabel,unitsY)
   params.YLabel = sprintf('%s %s',params.YLabel,unitsY);
end

end