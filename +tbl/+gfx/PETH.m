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
%
% See also: Contents, tbl.gfx.batchPETH

PRE_OFFSET = -50; % milliseconds relative to stimulus to end "baseline"
N_SD = 3;         % # Of standard deviations to set threshold above "baseline"
X_UNITS = '(ms)';          % X-label units
Y_UNITS = '\surd(Spikes/sec)';  % Y-label units

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
[fig,ax] = utils.getFigAx(params,'PETH');
if istable(T)
   T = tbl.slice(T,filtArgs{:}); % Apply filters to table

   % Get time variable and the data to plot, so that each row represents a
   % time-step. Make sure time is a column vector:
   t = reshape(T.Properties.UserData.t.Spikes,numel(T.Properties.UserData.t.Spikes),1); 
   if max(abs(t)) < 2
      t = t.*1e3; % Convert to milliseconds
   end

   % The filtering that determines whether this is at the "per-channel" or
   % "per-group" level has already been done via the input arguments. If you
   % need to make a "tiled" array of subplots with individual-channel
   % histograms, then call `tbl.gfx.PETH(T,...);` with `filtArgs` as appropriate
   % for each channel, one at a time (or via 'splitApply' workflow in
   % combination with the data table).
   X = T.Spikes.'; % "Flip" the matrix so that rows are timesteps
   
else % Otherwise, this was passed via `splitapply` and args are different
   % T is now `t`
   t = reshape(T,numel(T),1);
   if max(abs(t)) < 2
      t = t.*1e3; % Convert to milliseconds
   end
   X = filtArgs;
   if size(X,1) ~= size(t,1)
      X = X.';
   end
end
dt = nanmean(diff(t));

if istable(T)
   if size(T,1) < 1
      error('GFX:PETH:NoTableRows',...
         ['Double-check `<strong>filtArgs</strong>` or `<strong>T</strong>`:' ...
             'no table rows meet criteria.']);
   end
   
   c = params.GroupColor.Color(params.GroupColor.Type==string(T.Type(1)),:);
   o = params.GroupColorOffset.(string(T.Area(1)));
   params.Color = c + o;
end

% % % Add actual data % % %
% At this point, we should only have the rows remaining that we want to put
% on the axes. So we can just plot the median +/- the IQR in order to avoid
% outlier trials biasing the data too much.

% First, add helper repos
utils.addHelperRepos();
utils.addLabelsToAxes(ax,params);

Z = sqrt(X./(dt * 1e-3)); % Convert to sqrt(spikes/sec)
mu = nanmean(Z,2); % Get mean for histograms
bar(ax,t,mu,1,'DisplayName','PETH','FaceColor',params.Color,...
   params.BarParams{:});

% IQR = iqr(Z(:));
Z_s = sgolayfilt(Z,params.SGOrder,params.SGLen,ones(1,params.SGLen),1);
cb_s = utils.getCB95(Z_s,2); % Get confidence band for each "row" (2)
mu_s = nanmean(Z_s,2);

% Superimpose shaded error to show IQR
% gfx__.plotWithShadedError(ax,t,Z,params.ShadedErrorParams{:});
gfx__.plotWithShadedError(ax,t,mu_s,cb_s,...
   'FaceColor',params.Color,...
   'FaceAlpha',0.35,...
   'Color',params.Color,...
   'LineStyle','-',...
   'Annotation','on',...
   'LineWidth',2.5,...
   'Tag','CB95',...
   'Annotation','on',...
   'DisplayName','Trial Mean \pm95% CI (Smoothed)',...
   params.ShadedErrorParams{:}...
);

% Superimpose threshold set by pre-stimulus level of activity
P = Z(t < PRE_OFFSET,:);
mu_thresh = nanmean(P(:));
sd_thresh = nanstd(P(:));
thresh = mu_thresh + N_SD*sd_thresh;
line(ax,[min(t) max(t)],[thresh, thresh],'Color','m','LineWidth',2,...
   'LineStyle','--',...
   'DisplayName',sprintf('Pre-Stimulus Mean + %d*SD (Threshold)',N_SD));
if ax.YLim(2) < (thresh+sd_thresh)
   set(ax,'YLim',[0 thresh+sd_thresh]);
else
   set(ax,'YLim',[0 ax.YLim(2)]);
end

set(ax,'YLim',[0 ax.YLim(2)]);

% Add any trial-type related metadata (solenoid or ICMS strikes) %
if istable(T)
   utils.addStimInfoToAxes(ax,T,params,'west');
end
% % Add any legend/labels as the very last things
% utils.addLegendToAxes(ax,params,'Location','northeast');
utils.addTextToAxes(ax,sprintf('\\bf\\itN\\rm = %d',size(Z,2)),'northeast','Color',[0 0 0]);
if istable(T)
   utils.addAreaToAxes(ax,T,params,'northwest','BackgroundColor',[1 1 1]);
end

end