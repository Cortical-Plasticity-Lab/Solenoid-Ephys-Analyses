function [fig,params] = PETH(T,varargin)
%PETH Generate/export peri-event time histograms (PETH)
%
%  fig = tbl.gfx.PETH(T);
%  fig = tbl.gfx.PETH(T,...);
%  [fig,params] = ...
%
% Inputs
%  T        - Table exported using solRat.makeTables
%  varargin - (Optional) pairs of 'Name', value inputs
%
% Output
%  fig      - Figure handle for generated PETH
%  params   - Parameters struct

% Parse inputs %
params = cfg.gfx(); % Loads default parameters
params = utils.getOpt(params,3,varargin{:}); % Match optional parameters

% % User can pass `Axes` or `Figure` using 'Axes' or 'Figure' pairs % %
% This can be useful for generating subplots, etc.
if isempty(params.Figure)
   if isempty(params.Axes)
      fig = figure('Name','PETH',params.FigureParams{:});
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

% Add figure using `fig` or `ax` etc %

end