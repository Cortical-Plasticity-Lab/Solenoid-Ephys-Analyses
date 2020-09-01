function label = formatDefaultLabel(label,varargin)
%FORMATDEFAULTLABEL Apply default font settings preferred by MM
%
%  label = utils.formatDefaultLabel(label);
%  label = utils.formatDefaultLabel(label,'Name',value,...);
%
%  Example:
%     utils.formatDefaultLabel(title(ax,'TitleString'));
%        -> Apply preferred 'Name',value properties to title object
%
% Inputs
%  label - Axes handle or array of axes to format
%  varargin - (Optional) 'Name',value argument pairs. See Title properties
%              in Matlab documentation for list.
%
% Output
%  label - Formatted label handles. Not necessary to return them, since the
%          changes will apply to the object handles that you supply to the
%          function regardless.
%
%  Note: use utils.addLabelsToAxes if working with functions where you have 
%        the parameters struct, this is for if you are just quickly making 
%        a figure in a script.
%
% See also: utils, utils.addLabelsToAxes
for iLab = 1:numel(label)
   set(label(iLab),...
      'Color','k',...         % This makes it nicer in Adobe Illustrator
      'FontName','Arial',...  % Adobe does not understand Helvetica
      'FontWeight','bold',... % Make the lines more robust in Illustrator
      'FontSize',16);         % Help old and tired eyes out  
end
end