function txtObj = addAreaToAxes(ax,T,params,txtLoc,varargin)
%ADDAREATOAXES Add label to axes indicating 'RFA' or 'S1' in a principled way
%
%  txtObj = utils.addAreaToAxes(ax,T,params);
%  txtObj = utils.addAreaToAxes(ax,T,params,txtLoc);
%
% Inputs
%  ax       - Axes handle to add to
%  T        - Table that has already had "slicing" applied
%  params   - Parameters struct with field 'Color'
%  txtLoc   - (Optional) 'northwest' (def) | 'north', etc... (see
%                 utils.addTextToAxes)
%
% Output
%  txtObj   - Text object (i.e. label of RFA or S1)
%
% See also: utils, utils.addTextToAxes, tbl.gfx, tbl.gfx.PEP, tbl.gfx.PETH

if nargin < 4
   txtLoc = 'northwest';
end

area = unique(string(T.Area));
txt = strjoin(area,'+');
[ch,ich] = unique(T.ChannelID);
if numel(ch)==1
   d = T.Depth(ich);
   txt = sprintf('\\bf%s \\rm(%s | \\it%5.2f\\mum\\rm)',txt,ch,d);
end

if nargout > 0
   txtObj = utils.addTextToAxes(ax,txt,txtLoc,'Color',params.Color,varargin{:});
else
   utils.addTextToAxes(ax,txt,txtLoc,'Color',params.Color,varargin{:});
end

end