function txtObj = addTypeToAxes(ax,T,params,txtLoc)
%ADDTYPETOAXES Add label to axes indicating 'Solenoid (only)', 'ICMS (only)', or 'Solenoid+ICMS' in a principled way
%
%  txtObj = utils.addTypeToAxes(ax,T,params);
%  txtObj = utils.addTypeToAxes(ax,T,params,txtLoc);
%
% Inputs
%  ax       - Axes handle to add to
%  T        - Table that has already had "slicing" applied
%  params   - Parameters struct with field 'Color'
%  txtLoc   - (Optional) 'north' (def) | 'northeast', etc... (see
%                 utils.addTextToAxes)
%
% Output
%  txtObj   - Text object (i.e. label of RFA or S1)
%
% See also: utils, utils.addTextToAxes, tbl.gfx, tbl.gfx.PEP, tbl.gfx.PETH

if nargin < 4
   txtLoc = 'north';
end

txt = strjoin(string(cfg.TrialType(double(unique(T.Type)))),' + ');
if nargout > 0
   txtObj = utils.addTextToAxes(ax,txt,txtLoc,'Color',params.Color);
else
   utils.addTextToAxes(ax,txt,txtLoc,'Color',params.Color);
end

end