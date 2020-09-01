function ax = formatDefaultAxes(ax,varargin)
%FORMATDEFAULTAXES Apply default axes settings preferred by MM
%
%  ax = utils.formatDefaultAxes(ax);
%  ax = utils.formatDefaultAxes(ax,'Name',value,...);
%
% Inputs
%  ax - Axes handle or array of axes to format
%  varargin - (Optional) 'Name',value argument pairs. See Axes properties
%              in Matlab documentation for list.
%
% Output
%  ax - Formatted axes handles. Not necessary to return them, since the
%        changes will apply to the object handles that you supply to the
%        function regardless.
%
%  Note: use utils.getFigAx if working with functions where you have the
%        parameters struct, this is for if you are just quickly making a
%        figure in a script.
%
% See also: utils

for iAx = 1:numel(ax)
   set(ax(iAx),...
      'NextPlot','add',... % Allow to add multiple graphics, same as "hold on"
      'XColor','k',... % This makes it nicer in Adobe Illustrator
      'YColor','k',... % This makes it nicer in Adobe Illustrator
      'LineWidth',1.5,...    % Make the axes thicker (nicer in Adobe)
      'FontName','Arial',... % Adobe does not understand Helvetica
      varargin{:});  % And any other 'Name',value arguments to apply (note that these can overwrite "defaults" set previously)
end
end