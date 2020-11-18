%% Set variables
clc; clearvars -except T
if exist('T','var')==0
   T = getfield(load('Solenoid-Table_5-ms_excluded_ipsi.mat','T'),'T');
end

binSt = 51;   % 0 time bin
pk = 5;       % Number of peaks
nSD = 3;      % # Standard deviations
thresh = 2.4; % Spikes/sec

binSize = T.Properties.UserData.settings.binwidth;
binEnd = numel(T.Properties.UserData.t.Spikes); % Last bin
buff = ceil(10/binSize); % Buffer at least 10ms before 0 timepoint
preBin = binSt - buff;
%% Eliminate channels with low spiking rates
bt = (1+buff):(binEnd-buff); % Buffer edges of baseline period
dur = ((binEnd-buff) - (1+buff))*binSize; % Determine duration in sec

[T_small,B]= tbl.elimCh(T,bt,dur,thresh);
%% Create table 'C' with mean spikes per channel
C = analyze.meanSpikesPerChannel(T_small,B,nSD,binSt,binSize,pk);

% Plot histogram of overall distribution of peaks
fig = figure('Name','Distribution of Peak Times','Color','w');
ax = axes(fig,'NextPlot','add','XColor','k','YColor','k','FontName','Arial');
histogram(ax,C.ampTime*1000,0:5:300);
xlabel(ax,'Time (ms)','Color','k','FontName','Arial');
ylabel(ax,'Count (channels/block/type)','Color','k','FontName','Arial');
title(ax,'Distribution of Evoked Spike Peak times (all types)','FontName','Arial','Color','k');
io.optSaveFig(fig,'figures/new_analysis','A - All Spike Peak Times Histogram');
d = nansum(C.ampTime(~isnan(C.ampMax))*1e3 - (C.pkTime(~isnan(C.ampMax)) - (binSize*1e3)/2));
if d < (0.001 - eps)
   fprintf(1,'<strong>Good:</strong> Method difference is less-than <strong>%5.3f</strong> (ms)\n',round(d,3));
else
   fprintf(1,'<strong>Bad:</strong> Method difference is <strong>%5.3f</strong> (ms)\n',round(d,3));
end

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
clearvars -except C
tic;
fprintf(1,'Saving table <strong>`C`</strong>...');
save('Fig3_Table.mat','C','-v7.3');
fprintf(1,'complete (%5.2f sec)\n',toc);