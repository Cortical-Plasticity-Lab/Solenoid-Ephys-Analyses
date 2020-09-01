function fig = formatDefaultFigure(fig,varargin)
%FORMATDEFAULTFIGURE Apply default figure settings preferred by MM
%
%  fig = utils.formatDefaultFigure(fig);
%  fig = utils.formatDefaultFigure(fig,'Name',value,...);
%
% Inputs
%  fig - Figure handle or array of figures to format
%  varargin - (Optional) 'Name',value argument pairs. See Figure properties
%              in Matlab documentation for list.
%
% Output
%  fig - Formatted figure handles. Not necessary to return them, since the
%        changes will apply to the object handles that you supply to the
%        function regardless. However, can be convenient on object
%        constructor.
%
%  Note: use utils.getFigAx if working with functions where you have the
%        parameters struct, this is for if you are just quickly making a
%        figure in a script.
%
% See also: utils, utils.getFigAx 

POS = [0.25 0.25 0.4 0.4]; % Default array [x y w h] for position
J   = [0.05 0.05 0.0 0.0]; % Array jitter in [x y w h] for position

for iFig = 1:numel(fig)
   % Make random figure position that is jittered slightly for array
   pos = POS + randn(1,4).*J;
   set(fig(iFig),...
      'NumberTitle','off',...    % Preference
      'Color','w',...            % White background
      'Units','Normalized',...   % Easier to get position using normalized coordinates
      'Position',pos);           % This will make it so not every new figure overlaps when it pops ups
end
end