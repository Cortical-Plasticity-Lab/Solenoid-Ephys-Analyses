function [fig,ax] = getFigAx(params,figName)
%GETFIGAX Return figure and axes handles given parameters struct
%
%  [fig,ax] = utils.getFigAx(params);
%  [fig,ax] = utils.getFigAx(params,'Figure Name');
%  
% Inputs
%  params  - Parameters struct, which should have the fields 'Axes' and
%              'Figure' at least. If no default 'Axes' and/or 'Figure' are
%              provided, still specify those two fields but leave them as
%              empty doubles (i.e. [])
%  figName - (Optional) char array or string that is the 'Name' parameter
%                       of the figure.
%
% Output
%  fig     - Figure handle
%  ax      - Axes handle

if nargin < 2
   figName = 'Figure';
end

if isempty(params.Figure)
   if isempty(params.Axes)
      fig = figure('Name',figName,params.FigureParams{:});
      ax = axes(fig,params.AxesParams{:});
   else
      ax = params.Axes;
      fig = get(ax,'Parent');
      if ~isa(fig,'matlab.ui.Figure')
         fig = gcf;
      end
   end
   params.Axes = ax;
   params.Figure = fig;
else
   fig = params.Figure;
   if isempty(params.Axes)
      params.Axes = axes(fig,params.AxesParams{:});
   end
   ax = params.Axes;
end

end