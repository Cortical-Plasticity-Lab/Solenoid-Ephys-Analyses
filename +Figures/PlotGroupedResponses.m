function fig = PlotGroupedResponses(C,groupings,response,varargin)
%PLOTGROUPEDRESPONSES Compare arbitrarily grouped distributions of observed time-series averages of interest using histograms and smoothed trends
%
%  fig = Figures.PlotGroupedResponses(C,groupings,response);
%  fig = Figures.PlotGroupedResponses(C,groupings,response,'Name',value,...);
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
   struct('XCoordinate','ms',...
          'YCoordinate','',...
   'CoordinateSpec','%4.1f-%s'); % For labeling abscissae on point labels marked on each subplot
pars.Axes_Coordinate_Marker_Args = [2,1]; % [1,2,3,4] : [xlabel, xpeakpos, ylabel, ypeakpos]
pars.Bar_Args = repmat({{}},N,1);    % Cell array with one entry per group of group-specific parameter pairs for each grouping histogram graphic
pars.Bins = [];               % Default histogram bin edges (ms)
pars.Color = [0 0 0];         % Colors corresponding to each subplot
pars.ExclusionThreshold = [-inf inf]; % Setting range to [-inf, inf] includes all data. This can be changed to restrict to only valid values, but depends on response.
pars.Figure_Args = {};        % Extra figure parameter pairs
pars.FigureName = 'Distributions'; % Name of figure
pars.FindPeaks_Args = {};     % Extra parameter pairs for `findpeaks` algorithm
pars.Line_Args = repmat({{}},N,1);     % Cell array with one entry per group of group-specific parameter pairs for each grouping of KDE graphic line
pars.Label_Args = {};               % Default axes label parameter pairs
pars.LegendLocation = 'northeast';  % Default legend location
pars.NameIndices = [];
pars.NPeaks = 1;
pars.PC_Color_Order = [0 0 1; 1 0 0; 1 1 0]; % Blue, Red, Yellow
pars.PC_Type = "Solenoid";
pars.PeakMarker_Args = {};          % Extra parameter value pairs for utils.addPeakLabels()
pars.PeaksAfter = 0; % ms
pars.SG_FrameLen = 21;
pars.SG_Order = 2;
pars.XLabel = '\bf\itt\rm \bf(time, ms)';    % Default string for XLabel (LaTeX formatting)
pars.YLabel = '\bfScore(\itRMS(LFP)\rm\bf,\itt\rm\bf) | \muV';          % Default string for YLabel (LaTeX formatting)
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
idx = any(C.(response) < pars.ExclusionThreshold(1),2) | ...
      any(C.(response) > pars.ExclusionThreshold(2),2);
C(idx,:) = [];

if isempty(pars.Bins)
   if isstruct(C.Properties.UserData)
      if isfield(C.Properties.UserData,'t')
         if isfield(C.Properties.UserData.t,response)
            pars.Bins = C.Properties.UserData.t.(response);
         end
      end
   end
end
fig = gobjects(2,1);

fig(1) = utils.formatDefaultFigure(figure,...
   'Name',pars.FigureName,...
   'UserData',struct('Excluded',sum(idx)),...
   pars.Figure_Args{:});

% Recover the total number of subplot rows & columns
nRow = floor(sqrt(N));
nCol = ceil(N/nRow);
varNames = groupings.Properties.VariableNames;
if isempty(pars.PC_Type)
   pc_idx = true(size(C,1),1);
else
   pc_idx = C.Type==pars.PC_Type;
end

[DATA,SCORE,coeff,explained] = utils.getPCs(C.(response),pc_idx);

if ~isempty(pars.Bins)
   SD = nanstd(SCORE(pars.Bins > pars.PeaksAfter,:),[],1);
   SCORE = SCORE./SD;
   MU = nanmean(SCORE(pars.Bins > pars.PeaksAfter,:),1);
   TS = (SCORE(pars.Bins > pars.PeaksAfter,1:3)-MU(1:3)).^2;
   TSS = sum(TS(:));
end

for ii = 1:N % Total number of rows in groupings table
   % First: identify indices of included rows from `C` for this subplot.
   idx = true(size(DATA,1),1);
   titleStr = strings(1,numel(varNames));
   if isempty(pars.NameIndices)
      nameVec = 1:min(2,numel(varNames));
   else
      nameVec = reshape(pars.NameIndices,1,numel(pars.NameIndices));
   end
   for iG = nameVec
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
   
   [data,score] = utils.applyPCs(DATA,coeff,pc_idx(idx));
   
   ax = utils.formatDefaultAxes(subplot(nRow,nCol,ii),...
      'Parent',fig(1),...
      'UserData',pars.Axes_Coordinate_Labels,...
      pars.Axes_Args{:}); % Helper to apply MM-preferred axes properties
   if ~isempty(pars.XLim)
      xlim(ax,pars.XLim);
   end
   if ~isempty(pars.YLim)
      ylim(ax,pars.YLim);
   end
   if isempty(pars.Bins)
      R2 = nan;
      plot(ax,data.','Color',[0.5 0.5 0.5],'LineWidth',1);
      l = plot(ax,score(:,1:3),...
         'Color',pars.Color(ii,:),pars.Line_Args{ii}{:});
      
   else
      score_z = score./nanstd(score,[],1);
      RS = (SCORE(pars.Bins > pars.PeaksAfter,1:3) - score_z(pars.Bins > pars.PeaksAfter,1:3)).^2;
      RSS = sum(RS(:));
      R2 = 1 - RSS/TSS;
      score(pars.Bins > pars.PeaksAfter,:) = sgolayfilt(...
         score(pars.Bins > pars.PeaksAfter,:),pars.SG_Order,pars.SG_FrameLen);
      tS = repmat(pars.Bins,sum(pc_idx(idx)),1);
      scatter(ax,tS(:)+randn(numel(tS),1).*0.5,data(:),...
         'MarkerFaceColor',[0.5 0.5 0.5],...
         'Marker','o','MarkerEdgeColor','none',...
         'MarkerFaceAlpha',0.025,'SizeData',4);
      l = plot(ax,pars.Bins,score(:,1:3),...
         'Color',pars.Color(ii,:),pars.Line_Args{ii}{:});
      
   end
   for iL = 1:numel(l)
      set(l(iL),...
         'Color',pars.PC_Color_Order(iL,:),...
         'DisplayName',sprintf('PC-%02d',iL),...
         'LineWidth',2/(1+exp(-(iL-1))));
      if iL == 1
         [pks,loc_idx] = findpeaks(abs(l(iL).YData),...
            'NPeaks',pars.NPeaks,...
            'SortStr','descend',...
            'MinPeakDistance',40,...
            pars.FindPeaks_Args{:});
         locs = l(iL).XData(loc_idx);
         iPk = locs > pars.PeaksAfter;
         pks = pks(iPk);
         locs = locs(iPk);
         loc_idx = loc_idx(iPk);
         pks = pks .* sign(l(iL).YData(loc_idx));
         utils.addPeakLabels(ax,locs,pks,[],...
            'Color',pars.PC_Color_Order(iL,:),...
            'Clipping','on',...
            'CoordinateMarkerArgs',pars.Axes_Coordinate_Marker_Args,...
            pars.PeakMarker_Args{:});
      end
   end
   
   
   title(ax,titleStr,'FontName','Arial','Color','k','FontSize',11);
   if rem(ii,nCol)==1
      ylabel(ax,pars.YLabel,'FontName','Arial','Color','k');
   end
   if ii > ((nRow-1)*nCol)
      xlabel(ax,pars.XLabel,'FontName','Arial','Color','k');
   end
   line(ax,ones(1,2).*pars.PeaksAfter,ax.YLim,...
      'LineStyle',':','Color','m',...
      'LineWidth',2.5,'DisplayName','Stimulus');
   
   R2_str = sprintf('R^2: %0.3f',R2);
   utils.addTextToAxes(ax,R2_str,'southeast',...
      'BackgroundColor',[1 1 1],...
      'X_SCALE',0.8,'Y_SCALE',0.8);
end
suptitle(strrep(response,'_',' '));

fig(2) = utils.formatDefaultFigure(figure,...
   'Name','Principal Components',...
   'UserData',struct('Excluded',sum(idx)),...
   pars.Figure_Args{:});
explained_cumulative = cumsum(explained);
ax = utils.formatDefaultAxes(subplot(2,1,1),...
   'Parent',fig(2),...
   'Clipping','on',...
   pars.Axes_Args{:});
title(ax,[strrep(response,'_',' ') ': Variance Explained'],'FontName','Arial','Color','k');
ylabel(ax,'Percent Variance','FontName','Arial','Color','k');
xlabel(ax,'Component','FontName','Arial','Color','k');
for ii = 1:3
   stem(ax,ii,explained_cumulative(ii),'DisplayName',sprintf('PC-%02d',ii),...
      'Color',pars.PC_Color_Order(ii,:),'LineWidth',2,...
      'MarkerFaceColor',pars.PC_Color_Order(ii,:));
end
stem(ax,4:numel(explained_cumulative),explained_cumulative(4:end),...
   'DisplayName','Remaining PCs',...
   'Color','k','LineWidth',1.5);
legend(ax,'TextColor','black','FontName','Arial','Location','best');
set(ax,'YTick',0:25:100,'XTick',1:numel(explained_cumulative),...
   'XLim',[0 12.5],...
   'YLim',[0 100]);
ax = utils.formatDefaultAxes(subplot(2,1,2),...
   'Parent',fig(2),...
   pars.Axes_Args{:});
title(ax,'PC Scores','FontName','Arial','Color','k');
ylabel(ax,'Score','FontName','Arial','Color','k');
xlabel(ax,'Time (ms)','FontName','Arial','Color','k');
ax.ColorOrder = pars.PC_Color_Order;
plot(ax,pars.Bins,SCORE(:,1:3),'LineWidth',2);
% if ~isempty(pars.YLim) && ~any(isnan(pars.YLim))
%    set(ax,'YLim',pars.YLim);
% end
if ~isempty(pars.XLim) && ~any(isnan(pars.XLim))
   set(ax,'XLim',pars.XLim);
end
end