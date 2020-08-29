function txtObj = addTextToAxes(ax,txt,txtLoc,varargin)
%ADDTEXTTOAXES Add text to a specified location on an axes
%
%  txtObj = utils.addTextToAxes(ax,txt,txtLoc,'Name',value,...);
%
% Example:
%  ```
%     fig = figure;
%     ax  = axes(fig);
%     utils.addTextToAxes(ax,'testSouthWest','southwest');
%     utils.addTextToAxes(ax,'testWest','west','Color','r');
%     utils.addTextToAxes(ax,'testNorthWest','Northwest');
%     utils.addTextToAxes(ax,'testNorth','North','FontWeight','bold');
%     utils.addTextToAxes(ax,'testNorthEast','NorthEast');
%     utils.addTextToAxes(ax,'testEast','East','BackgroundColor','b');
%     utils.addTextToAxes(ax,'testSouthEast','SouthEast');
%     utils.addTextToAxes(ax,'testSouth','South');
%  ```
%
% Inputs
%  ax       - Axes handle
%  txt      - String or char array to display in text
%  txtLoc   - 'northwest' (def) | 'north' | 'northeast' | 'east' |
%              'southeast' | 'south' | 'southwest' | 'west'
%  varargin - (Optional) 'Name',value input argument pairs for Font
%                 parameters or other text 'Name',value parameters
%              * 'X_SCALE' : 1 (def) | scalar that changes relative x-loc
%              * 'Y_SCALE' : 1 (def) | scalar that changes relative y-loc
%
% Output
%  txtObj   - Text object
%
% See also: utils, tbl.gfx, tbl.gfx.PEP, tbl.gfx.PETH

X_SCALE = 1;
Y_SCALE = 1;

if nargin < 3
   txtLoc = 'northwest';
end

[X_SCALE,varargin] = utils.parseNamedVariable(varargin,X_SCALE);
[Y_SCALE,varargin] = utils.parseNamedVariable(varargin,Y_SCALE);

switch lower(txtLoc)
   case 'northwest'
      g = [0.025 0.975];
      hAlign = 'left';
      vAlign = 'cap';
   case 'north'
      g = [0.500 0.975];
      hAlign = 'center';
      vAlign = 'cap';
   case 'northeast'
      g = [0.975 0.975];
      hAlign = 'right';
      vAlign = 'cap';
   case 'east'
      g = [0.975 0.500];
      hAlign = 'right';
      vAlign = 'middle';
   case 'southeast'
      g = [0.975 0.025];
      hAlign = 'right';
      vAlign = 'baseline';
   case 'south'
      g = [0.500 0.025];
      hAlign = 'center';
      vAlign = 'baseline';
   case 'southwest'
      g = [0.025 0.025];
      hAlign = 'left';
      vAlign = 'baseline';
   case 'west'
      g = [0.025 0.500];
      hAlign = 'left';
      vAlign = 'middle';
      
   otherwise
      error('Invalid txtLoc specification ("%s")',txtLoc);
end
% Get <x,y> coordinate for text
x = g(1)*diff(ax.XLim)*X_SCALE + ax.XLim(1);
y = g(2)*diff(ax.YLim)*Y_SCALE + ax.YLim(1);

if nargout > 0
   txtObj = text(ax,x,y,txt,...
      'VerticalAlignment',vAlign,...
      'HorizontalAlignment',hAlign,...
      'FontName','Arial',...
      'Color',[0 0 0],...
      'FontWeight','bold',...
      varargin{:});
else
   text(ax,x,y,txt,...
      'VerticalAlignment',vAlign,...
      'HorizontalAlignment',hAlign,...
      'FontName','Arial',...
      'Color',[0 0 0],...
      'FontWeight','bold',...
      varargin{:});
end


end