%% Set variables
clc; close all force; clearvars -except T
if exist('T','var')==0
   T = getfield(load('Solenoid-Table_5-ms_excluded_ipsi.mat','T'),'T');
end

%% Get subset of data
N_PK             = 8;        % Number of peaks
N_SD             = 5;        % # Standard deviations for "adaptive" threshold
FIXED_RAW_THRESH = 2.4;      % Spikes/sec
EVOKED_WINDOW = [0.005 0.350];      % ONLY find peaks in this window (seconds)
RATE_UPPER_LIMIT = 500;             % Remove values greater than this
MIN_SPIKE_RATE_PROMINENCE = 5;      % Peaks must have prominence of at least 5-Hz

% Select only "Active" channels (T_active) with a reasonably high FR
[T_active,B,fig]= tbl.elimCh(T,FIXED_RAW_THRESH);
io.optSaveFig(fig,'figures/new_analysis','A - Excluded Channels');

%% Create table 'C' with mean spikes per channel
% Get thresholds for each row of `C` using baseline activity:
C = analyze.assignBasalThreshold(T_active,B,N_SD); 

% Use thresholds and `findpeaks` to identify the top `N_PK` peaks:
[C,histFig,jointFig] = analyze.detectAverageEvokedSpikePeaks(C,...
   N_PK,...
   EVOKED_WINDOW,...
   RATE_UPPER_LIMIT,...
   MIN_SPIKE_RATE_PROMINENCE); 
io.optSaveFig(histFig,'figures/new_analysis','B - All Spike Peak Times Histogram');
io.optSaveFig(jointFig,'figures/new_analysis','C - Joint Peak Time Distribution (no jitter)');

%% 
disp('Plotting cumulative distribution functions (CDF)...');
fig = tbl.gfx.plotPeakTimeCDF(C,0,75,"Solenoid"); % Referenced to SOLENOID
io.optSaveFig(fig,'figures/new_analysis','D - Solenoid - Window Spike Peak Detect Upper Bound Sweep CDF');
fig = tbl.gfx.plotPeakTimeCDF(C,-75,300,"Solenoid"); % Referenced to SOLENOID
io.optSaveFig(fig,'figures/new_analysis','E - Solenoid - Window Spike Peak Detect Lower Bound Sweep CDF');

fig = tbl.gfx.plotPeakTimeCDF(C,0,75,"ICMS"); % Referenced to SOLENOID
io.optSaveFig(fig,'figures/new_analysis','F - ICMS - Window Spike Peak Detect Upper Bound Sweep CDF');
fig = tbl.gfx.plotPeakTimeCDF(C,-75,300,"ICMS"); % Referenced to SOLENOID
io.optSaveFig(fig,'figures/new_analysis','G - ICMS - Window Spike Peak Detect Lower Bound Sweep CDF');

%%
clearvars -except B C T
tic;
fprintf(1,'Saving table <strong>`C`</strong>...');
save('Fig3_Table.mat','C','-v7.3');
fprintf(1,'complete (%5.2f sec)\n',toc);

%%
% run_stats;