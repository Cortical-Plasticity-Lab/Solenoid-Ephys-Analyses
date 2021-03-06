function [fig,params] = PEP(T,filtArgs,varargin)
%PEP Generate/export peri-event potentials (extracllular LFP averages)
%
%  fig = tbl.gfx.PEP(T,filtArgs);
%  fig = tbl.gfx.PEP(T,filtArgs,'Name',value,...);
%  fig = tbl.gfx.PEP(ax,T,filtArgs,...);
%  fig = tbl.gfx.PEP(t,X,'Name',value,...);
%  fig = tbl.gfx.PEP(ax,t,X);
%  [fig,params] = ...
%
% Inputs
%  T        - Table exported using solRat.makeTables
%  filtArgs - Cell array of 'Name',value pairs for filtering table
%              -> e.g. {'Variable1',value1,'Variable2',value2...}
%  varargin - (Optional) pairs of 'Name', value inputs
%
% -- or --
%  t        - Column vector of sample times for each LFP sample to plot
%  X        - Matrix where each row is a time-step and each column is a
%              different trial (possibly from multiple channels, possibly
%              not, it depends on how "slicing" was done). 
%
% Output
%  fig      - Figure handle for generated PEP
%  params   - Parameters struct

X_UNITS = '(ms)';       % X-label units
Y_UNITS = '(\muV)';     % Y-label units

% Parse inputs %
params = cfg.gfx(); % Loads default parameters
if isa(T,'matlab.graphics.axis.Axes')
   params.Axes = T;
   T = filtArgs;
   if numel(varargin) > 0
      filtArgs = varargin{1};
      varargin(1) = [];
   elseif ~istable(T)
      error('If axes is first argument, and time is second, MUST provide data vector X as third argument!');
   else
      filtArgs = {};
   end
end

params = utils.getOpt(params,3,varargin{:}); % Match optional parameters
params = utils.checkXYLabels(params,X_UNITS,Y_UNITS);
params = utils.parseTitle(params,filtArgs);

% % User can pass `Axes` or `Figure` using 'Axes' or 'Figure' pairs % %
% This can be useful for generating subplots, etc.
[fig,ax] = utils.getFigAx(params,'PEP');
if istable(T)
   T = tbl.slice(T,filtArgs{:}); % Apply filters to table

   % Get time variable and the data to plot, so that each row represents a
   % time-step. Make sure time is a column vector:
   t = reshape(T.Properties.UserData.t.LFP,numel(T.Properties.UserData.t.LFP),1); 

   % The filtering that determines whether this is at the "per-channel" or
   % "per-group" level has already been done via the input arguments. If you
   % need to make a "tiled" array of subplots with individual-channel LFP
   % averages, then call `tbl.gfx.PEP(T,...);` with `filtArgs` as appropriate
   % for each channel, one at a time (or via 'splitApply' workflow in
   % combination with the data table).
   X = T.LFP.'; % "Flip" the matrix so that rows are timesteps
else % Otherwise, this was passed via `splitapply` and args are different
   % T is now `t`
   t = reshape(T,numel(T),1);
   X = filtArgs;
   if size(X,1) ~= size(t,1)
      X = X.';
   end
end

if istable(T)
   c = params.GroupColor.Color(params.GroupColor.Type==string(T.Type(1)),:);
   o = params.GroupColorOffset.(string(T.Area(1)));
   params.Color = c + o;
end

fs = 1/mean(diff(t*1e-3));
[b,a] = butter(2,([0.25, 10])./fs,'bandpass');
X = filtfilt(b,a,X);

% % % Add actual data % % %
% At this point, we should only have the rows remaining that we want to put
% on the axes. So we can just plot the median +/- the IQR in order to avoid
% outlier trials biasing the data too much.

% First, add helper repos
utils.addHelperRepos();
utils.addLabelsToAxes(ax,params);

% Now, add the shaded error plot
gfx__.plotWithShadedError(ax,t,X,...
   'Tag','CB95',...
   'Annotation','on',...
   'DisplayName','Median \pm IQR',...
   'FaceAlpha',0.5,...
   'LineStyle','-',...
   'LineWidth',2,...
   'Color',params.Color,...
   params.ShadedErrorParams{:});
% Add any trial-type related metadata (solenoid or ICMS strikes) %
if istable(T)
   utils.addStimInfoToAxes(ax,T,params,'west');
end
% Add any legend/labels as the very last things
utils.addLegendToAxes(ax,params);
if istable(T)
   utils.addAreaToAxes(ax,T,params,'northwest');
end

end