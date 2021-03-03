%MARGINAL_STATS_FIGURES Export figures related to marginal values in GLME

clc;
clearvars -except glme

% load('run_stats_output.mat'); % Loads `mdl`
% glme = mdl.Full;
T = glme.Variables;
disp(glme.VariableInfo(glme.VariableInfo.InModel,{'Class','Range'}));

% Estimate marginal values (fixed effects only, no random effects)
peakVal_hat = predict(glme,T,'Conditional',false);

Area = unique(T.Area);
Type = unique(T.Type);
pars = cfg.gfx('AxesParams');

%% Make figures for marginal values by peak time
fig = figure(...
   'Name','Marginal Estimates: Peak Value by Peak Time',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.2 0.6 0.3]);
iPlot = 0;
xLim = [inf, -inf];
yLim = [inf, -inf];
for iArea = 1:numel(Area)
   for iType = 1:numel(Type)
      iPlot = iPlot + 1;
      ax = subplot(2,3,iPlot);
      set(ax,pars{:});
      if iType == 1
         ylabel(ax,'log(spikes/s)','FontName','Arial','Color','k');
      end
      if iArea == 2
         xlabel(ax,'Peak Time (sec)','FontName','Arial','Color','k');
      end
      title(ax,strcat(string(Area(iArea)),"::",string(Type(iType))),'FontName','Arial','Color','k');
      idx = T.Area == Area(iArea) & T.Type == Type(iType) & ...
         ~glme.ObservationInfo.Excluded;
      scatter(ax,...
         T.peakTime(idx),...
         peakVal_hat(idx),...
         'Marker','o',...
         'MarkerFaceColor','k',...
         'MarkerFaceAlpha',0.05,...
         'SizeData',(T.Lesion_Volume(idx)*2).^2,...
         'MarkerEdgeColor','none');
      xLim = [min(ax.XLim(1),xLim(1)), max(ax.XLim(2),xLim(2))];
      yLim = [min(ax.YLim(1),yLim(1)), max(ax.YLim(2),yLim(2))];
   end
end
for ii = 1:iPlot
   set(subplot(2,3,ii),'XLim',xLim,'YLim',yLim);
end
suptitle('Marginal Estimates: Peak Value by Peak Time');
io.optSaveFig(fig,'figures/marginal_stats','Marginal_By_Peak-Time');

%% Make figures for marginal values by depth
fig = figure(...
   'Name','Marginal Estimates: Peak Value by Depth',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.2 0.6 0.3]);
iPlot = 0;
xLim = [inf, -inf];
yLim = [inf, -inf];
for iArea = 1:numel(Area)
   for iType = 1:numel(Type)
      iPlot = iPlot + 1;
      ax = subplot(2,3,iPlot);
      set(ax,pars{:});
      if iType == 1
         ylabel(ax,'log(spikes/s)','FontName','Arial','Color','k');
      end
      if iArea == 2
         xlabel(ax,'Depth (\mum)','FontName','Arial','Color','k');
      end
      title(ax,strcat(string(Area(iArea)),"::",string(Type(iType))),'FontName','Arial','Color','k');
      idx = T.Area == Area(iArea) & T.Type == Type(iType) & ...
         ~glme.ObservationInfo.Excluded;
      scatter(ax,...
         T.Depth(idx),...
         peakVal_hat(idx),...
         'Marker','o',...
         'MarkerFaceColor','k',...
         'MarkerFaceAlpha',0.05,...
         'SizeData',(T.Lesion_Volume(idx)*2).^2,...
         'MarkerEdgeColor','none');
      xLim = [min(ax.XLim(1),xLim(1)), max(ax.XLim(2),xLim(2))];
      yLim = [min(ax.YLim(1),yLim(1)), max(ax.YLim(2),yLim(2))];
   end
end
for ii = 1:iPlot
   set(subplot(2,3,ii),'XLim',xLim,'YLim',yLim);
end
suptitle('Marginal Estimates: Peak Value by Depth');
io.optSaveFig(fig,'figures/marginal_stats','Marginal_By_Depth');

%% Make figures for Actual values by peak time
fig = figure(...
   'Name','Actual Values: Peak Value by Peak Time',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.2 0.6 0.3]);
iPlot = 0;
xLim = [inf, -inf];
yLim = [inf, -inf];
for iArea = 1:numel(Area)
   for iType = 1:numel(Type)
      iPlot = iPlot + 1;
      ax = subplot(2,3,iPlot);
      set(ax,pars{:});
      if iType == 1
         ylabel(ax,'log(spikes/s)','FontName','Arial','Color','k');
      end
      if iArea == 2
         xlabel(ax,'Peak Time (sec)','FontName','Arial','Color','k');
      end
      title(ax,strcat(string(Area(iArea)),"::",string(Type(iType))),'FontName','Arial','Color','k');
      idx = T.Area == Area(iArea) & T.Type == Type(iType) & ...
         ~glme.ObservationInfo.Excluded;
      scatter(ax,...
         T.peakTime(idx),...
         T.peakVal(idx),...
         'Marker','o',...
         'MarkerFaceColor','k',...
         'MarkerFaceAlpha',0.05,...
         'SizeData',(T.Lesion_Volume(idx)*2).^2,...
         'MarkerEdgeColor','none');
      xLim = [min(ax.XLim(1),xLim(1)), max(ax.XLim(2),xLim(2))];
      yLim = [min(ax.YLim(1),yLim(1)), max(ax.YLim(2),yLim(2))];
   end
end
for ii = 1:iPlot
   set(subplot(2,3,ii),'XLim',xLim,'YLim',yLim);
end
suptitle('Actual Values: Peak Value by Peak Time');
io.optSaveFig(fig,'figures/marginal_stats','Actual_By_Peak-Time');

%% Make figures for Actual values by depth
fig = figure(...
   'Name','Actual Values: Peak Value by Depth',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.2 0.6 0.3]);
iPlot = 0;
xLim = [inf, -inf];
yLim = [inf, -inf];
for iArea = 1:numel(Area)
   for iType = 1:numel(Type)
      iPlot = iPlot + 1;
      ax = subplot(2,3,iPlot);
      set(ax,pars{:});
      if iType == 1
         ylabel(ax,'log(spikes/s)','FontName','Arial','Color','k');
      end
      if iArea == 2
         xlabel(ax,'Depth (\mum)','FontName','Arial','Color','k');
      end
      title(ax,strcat(string(Area(iArea)),"::",string(Type(iType))),'FontName','Arial','Color','k');
      idx = T.Area == Area(iArea) & T.Type == Type(iType) & ...
         ~glme.ObservationInfo.Excluded;
      scatter(ax,...
         T.Depth(idx),...
         T.peakVal(idx),...
         'Marker','o',...
         'MarkerFaceColor','k',...
         'MarkerFaceAlpha',0.05,...
         'SizeData',(T.Lesion_Volume(idx)*2).^2,...
         'MarkerEdgeColor','none');
      xLim = [min(ax.XLim(1),xLim(1)), max(ax.XLim(2),xLim(2))];
      yLim = [min(ax.YLim(1),yLim(1)), max(ax.YLim(2),yLim(2))];
   end
end
for ii = 1:iPlot
   set(subplot(2,3,ii),'XLim',xLim,'YLim',yLim);
end
suptitle('Actual Values: Peak Value by Depth');
io.optSaveFig(fig,'figures/marginal_stats','Actual_By_Depth');