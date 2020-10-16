function fig = CompareGroupedResponses(C,groupings,response,varargin)
%COMPAREGROUPEDRESPONSES Compare arbitrarily grouped distributions of observed response variates of interest using histograms and smoothed trends
%
%  fig = Figures.CompareGroupedResponses(C,groupings,response);
%  fig = Figures.CompareGroupedResponses(C,groupings,response,'Name',value,...);
%
% Inputs
%  C           - Table output by tbl.stats.estimateChannelResponse
%  groupings   - Table where variables are the grouping variables and each
%                 row contains an acceptable combination of grouping
%                 values.
%  response    - Char array or string that is name of `C` response variable
%  varargin    - (Optional) 'Name',value parameter pairs. Most are cells
%                        that default as empty but can be used to supply
%                        additional parameter pair arguments to the
%                        corresponding Matlab built-in object (see "PARS"
%                        section in code for details).
%
% Output
%  fig      - Figure handle
%
% See also: Figures, example_response_estimation

% Make sure input is correct table
if ~strcmp(C.Properties.UserData.type,'ChannelResponseTable')
   error('Bad table type <strong>(%s)</strong>: should be ChannelResponseTable.\n',...
      C.Properties.UserData.type);
end

N = size(groupings,1);

% PARS % % % %
pars = struct;
pars.Axes_Args = {};          % Extra Axes parameter pairs
pars.Axes_Coordinate_Labels = ...
   struct('XCoordinate','',...
   'YCoordinate','p=',...
   'CoordinateSpec',['%s%4.1f ms' newline '%s%5.3f']); % For labeling abscissae on point labels marked on each subplot
pars.Bar_Args = repmat({{}},N,1);    % Cell array with one entry per group of group-specific parameter pairs for each grouping histogram graphic
pars.Bins = [];               % Default histogram bin edges (ms)
pars.Color = [0 0 0];         % Colors corresponding to each subplot
pars.ExclusionThreshold = [-inf inf]; % Setting range to [-inf, inf] includes all data. This can be changed to restrict to only valid values, but depends on response.
pars.Figure_Args = {};        % Extra figure parameter pairs
pars.FigureName = 'Distributions'; % Name of figure
pars.FindPeaks_Args = {};     % Extra parameter pairs for `findpeaks` algorithm
pars.Histogram_Args = {};     % Extra parameters for histogram estimation
pars.KDE_Args = {};              % Example: fig = Figures.CompareTimeToLFPMinima(C,'KDE_Args',{'Bandwidth',0.5}); % Changes the bandwidth on KDE estimator
pars.KDE_Line_Args = repmat({{}},N,1);     % Cell array with one entry per group of group-specific parameter pairs for each grouping of KDE graphic line
pars.KSMinProminence = 0.004;       % Minimum peak prominence (kernel smoother peaks)
pars.KSMinProximity = 0;            % (ms) minimum peak proximity
pars.Label_Args = {};               % Default axes label parameter pairs
pars.LegendLocation = 'northeast';  % Default legend location
pars.PeakMarker_Args = {};          % Extra parameter value pairs for utils.addPeakLabels()
pars.XLabel = '\bf\itt\rm \bf(time, ms)';    % Default string for XLabel (LaTeX formatting)
pars.YLabel = '\bfpdf(\itt\rm\bf)';          % Default string for YLabel (LaTeX formatting)
pars.XLim = []; % Can be specified as a fixed value
pars.YLim = [];
fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end
if size(pars.Color,1) < N
   pars.Color = repmat(pars.Color(1,:),N,1);
end
% END PARS % %

% Remove outlier rows
idx = (C.(response) < pars.ExclusionThreshold(1)) | ...
      (C.(response) > pars.ExclusionThreshold(2));
C(idx,:) = [];

fig = utils.formatDefaultFigure(figure,...
   'Name',pars.FigureName,...
   'UserData',struct('Excluded',sum(idx)),...
   pars.Figure_Args{:});

% Recover the total number of subplot rows & columns
nRow = floor(sqrt(N));
nCol = ceil(N/nRow);
varNames = groupings.Properties.VariableNames;
for ii = 1:N % Total number of rows in groupings table
   % First: identify indices of included rows from `C` for this subplot.
   idx = true(size(C,1),1);
   titleStr = strings(1,numel(varNames));
   for iG = 1:numel(varNames)
      if isnumeric(C.(varNames{iG}))
         idx = idx & ismember(C.(varNames{iG}),groupings.(varNames{iG})(ii));
         titleStr(iG) = num2str(groupings.(varNames{iG})(ii));
      elseif iscategorical(C.(varNames{iG}))
         if isnumeric(groupings.(varNames{iG})(ii))
            idx = idx & C.(varNames{iG})==groupings.(varNames{iG})(ii);
         else
            idx = idx & ismember(string(C.(varNames{iG})),string(groupings.(varNames{iG})(ii)));
         end
         titleStr(iG) = string(groupings.(varNames{iG})(ii));
      else
         idx = idx & ismember(C.(varNames{iG}),groupings.(varNames{iG})(ii));
         titleStr(iG) =  string(groupings.(varNames{iG})(ii));
      end
   end
   titleStr = strjoin(titleStr," ");
   data = C.(response)(idx);
   
   ax = utils.formatDefaultAxes(subplot(nRow,nCol,ii),...
      'Parent',fig,...
      'UserData',pars.Axes_Coordinate_Labels,...
      pars.Axes_Args{:}); % Helper to apply MM-preferred axes properties
   if ~isempty(pars.XLim)
      xlim(ax,pars.XLim);
   end
   if ~isempty(pars.YLim)
      ylim(ax,pars.YLim);
   end
   if isempty(pars.Bins)
      histogram(ax,data,...
         'FaceColor',pars.Color(ii,:),...
         'EdgeColor','none',...
         'Normalization','pdf',...
         pars.Histogram_Args{:});
   else
      histogram(ax,data,pars.Bins,...
         'FaceColor',pars.Color(ii,:),...
         'EdgeColor','none',...
         'Normalization','pdf',...
         pars.Histogram_Args{:});
   end
   set(findobj(ax.Children','Type','histogram'),...
      'DisplayName','Observed',...
      pars.Bar_Args{ii}{:});
   ksdensity(ax,data,...
      'Function','pdf',...
      'Kernel','Epanechnikov',...
      pars.KDE_Args{:}); % Epanechnikov: kernel is optimal with respect to minimizing mean-square error
   l = findobj(ax.Children,'Type','line');
   set(l,...
      'LineWidth',2.5,...
      'Color','k',...
      'LineStyle',':',...
      'DisplayName','Smoothed',...
      pars.KDE_Line_Args{ii}{:});
   [pks,locs] = findpeaks(l.YData,l.XData,...
      'MinPeakProminence',pars.KSMinProminence,...
      'MinPeakDistance',pars.KSMinProximity,...
      pars.FindPeaks_Args{:});
   if numel(pks) > 1
      utils.addConnectingLine(ax,locs(1:2),pks(1:2),[],...
         'LabelHorizontalAlignment','left',...
         'LabelVerticalAlignment','middle',...
         'Marker_Args',{'CoordinateMarkerArgs',2,'CoordinateSpec','\\Delta%4.1f ms'});
   end
   utils.addPeakLabels(ax,locs,pks,[],pars.PeakMarker_Args{:});
   utils.formatDefaultLabel(...
      [title(ax,titleStr);...
      xlabel(ax,pars.XLabel);...
      ylabel(ax,pars.YLabel)],...
      'Color',pars.Color(ii,:),...
      pars.Label_Args{:});
   utils.addLegendToAxes(ax,[],...
      'Location',pars.LegendLocation); % Add formatted axes
end
suptitle(strrep(response,'_',' '));
end