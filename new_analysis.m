%% Set variables
clc; clearvars -except T
if exist('T','var')==0
   T = getfield(load('Solenoid-Table_5-ms_excluded_ipsi.mat','T'),'T');
end

%% Get subset of data
N_PK             = 5;        % Number of peaks
N_SD             = 3;        % # Standard deviations for "adaptive" threshold
FIXED_RAW_THRESH = 2.4;      % Spikes/sec

% Select only "Active" channels (T_active) with a reasonably high FR
[T_active,B,fig]= tbl.elimCh(T,FIXED_RAW_THRESH);
io.optSaveFig(fig,'figures/new_analysis','A3 - Excluded Channels');

%% Create table 'C' with mean spikes per channel
C = analyze.meanSpikesPerChannel(T_active,B,N_SD,N_PK);

% Plot histogram of overall distribution of peaks
fig = figure('Name','Distribution of Peak Times','Color','w');
ax = axes(fig,'NextPlot','add','XColor','k','YColor','k','FontName','Arial');
histogram(ax,C.peakTime*1000,0:5:300);
xlabel(ax,'Time (ms)','Color','k','FontName','Arial');
ylabel(ax,'Count (channels/block/type)','Color','k','FontName','Arial');
title(ax,'Distribution of Evoked Spike Peak times (all types)','FontName','Arial','Color','k');
io.optSaveFig(fig,'figures/new_analysis','A - All Spike Peak Times Histogram');


fig = figure('Name','Distribution of Peak Times','Color','w');
ax = axes(fig,'NextPlot','add','XColor','k','YColor','k','FontName','Arial');
scatter(ax,...
   C.peakTime(:)*1000,C.peakVal(:),...
   'MarkerFaceColor','b','SizeData',4,...
   'MarkerEdgeColor','k','MarkerFaceAlpha',0.1,'MarkerEdgeAlpha',0.1);
xlabel(ax,'Peak Time (ms)','Color','k','FontName','Arial');
ylabel(ax,'Peak Value (\surd(spikes/sec))','Color','k','FontName','Arial');
title(ax,'Joint Distribution of Peaks and Times','FontName','Arial','Color','k');
io.optSaveFig(fig,'figures/new_analysis','A2 - Joint Peak Time Distribution (no jitter)');


%% 
disp('Plotting cumulative distribution functions (CDF)...');
fig = tbl.gfx.plotPeakTimeCDF(C,0,75,"Solenoid"); % Referenced to SOLENOID
io.optSaveFig(fig,'figures/new_analysis','B - Solenoid - Window Spike Peak Detect Upper Bound Sweep CDF');
fig = tbl.gfx.plotPeakTimeCDF(C,-75,300,"Solenoid"); % Referenced to SOLENOID
io.optSaveFig(fig,'figures/new_analysis','C - Solenoid - Window Spike Peak Detect Lower Bound Sweep CDF');

fig = tbl.gfx.plotPeakTimeCDF(C,0,75,"ICMS"); % Referenced to SOLENOID
io.optSaveFig(fig,'figures/new_analysis','D - ICMS - Window Spike Peak Detect Upper Bound Sweep CDF');
fig = tbl.gfx.plotPeakTimeCDF(C,-75,300,"ICMS"); % Referenced to SOLENOID
io.optSaveFig(fig,'figures/new_analysis','E - ICMS - Window Spike Peak Detect Lower Bound Sweep CDF');

%%
clearvars -except B C T
tic;
fprintf(1,'Saving table <strong>`C`</strong>...');
save('Fig3_Table.mat','C','-v7.3');
fprintf(1,'complete (%5.2f sec)\n',toc);

%%
% run_stats;