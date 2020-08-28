function [fig,params] = PETH(T,filtArgs,varargin)
%PETH Generate/export peri-event time histograms (PETH)
%
%  fig = tbl.gfx.PETH(T,filtArgs);
%  fig = tbl.gfx.PETH(T,filtArgs,...);
%  [fig,params] = ...
%
% Inputs
%  T        - Table exported using solRat.makeTables
%  filtArgs - Cell array of 'Name',value pairs for filtering table
%              -> e.g. {'Variable1',value1,'Variable2',value2...}
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
[fig,ax] = utils.getFigAx(params,'PETH');

% Add figure using `fig` or `ax` etc %

end