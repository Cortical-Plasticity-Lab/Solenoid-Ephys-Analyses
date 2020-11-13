%% Set variables
clc; clearvars -except T
if exist('T','var')==0
   T = getfield(load('Solenoid-Table_5-ms_excluded_ipsi.mat','T'),'T');
end

binSt = 51; % 0 time bin
pk = 5;
nSD = 3;

binSize = T.Properties.UserData.settings.binwidth;
binEnd = numel(T.Properties.UserData.t.Spikes); % Last bin
buff = ceil(10/binSize); % Buffer at least 10ms before 0 timepoint
preBin = binSt - buff;
%% Eliminate channels with low spiking rates
bt = (1+buff):(binEnd-buff); % Buffer edges of baseline period
dur = ((binEnd-buff) - (1+buff))*binSize; % Determine duration in sec
thresh = 2.4; % Spikes/sec
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

%% Plot histograms 
% disp('Plotting histograms...');
% histogram(C.ampBin(C.ampBin > 1),99) % Plot amplitudes
% [index,ref] = findgroups(C(:,{'ICMS_Onset','Solenoid_Onset','Area','Type'}));
% for i = 1:size(ref,1)
%     gr = index == i;
%     figure;
%     group = C.ampBin(gr,:);
%     histogram(group(group > 1),99);
%     hold on
%     v1 = table2array(ref(i,1));
%     v2 = table2array(ref(i,2));
%     v3 = char(table2array(ref(i,3)));
%     v4 = char(table2array(ref(i,4)));
%     varTitle = "ICMS %02d Solenoid %02d Area %s Type %s";
%     title(sprintf(varTitle,v1,v2,v3,v4));
%     hold off
% end

%% 
disp('Plotting cumulative distribution functions (CDF)...');
fig = tbl.gfx.plotPeakTimeCDF(C,0,75);
io.optSaveFig(fig,'figures/new_analysis','B - Window Spike Peak Detect Upper Bound Sweep CDF');
fig = tbl.gfx.plotPeakTimeCDF(C,-75,300);
io.optSaveFig(fig,'figures/new_analysis','C - Window Spike Peak Detect Lower Bound Sweep CDF');

%% Model
disp('Generating model...');
peakTime = C.pkTime.';
k = peakTime(:);
nC = repelem(C(1:end, :), pk, 1);
nC.pkTime = k;
nC.Spike_Mean = [];
nC.binom = nC.pkTime;
nC.binom(:) = 0;
nC = nC(nC.Type == 'Solenoid',:); % Look at solenoid trials only first
uniq = unique(nC.Solenoid_Onset);
for i = 1:numel(uniq)
    stim = uniq(i);
    idx = nC.Solenoid_Onset == stim;
    r1 = 25 + (uniq(i)*1e3);
    r2 = 55 + (uniq(i)*1e3);
    idx2 = nC.pkTime >= r1 & nC.pkTime <= r2;
    ind = idx & idx2;
    nC.binom(ind) = 1;
end
% mdl = fitcsvm(nC.pkTime,nC.binom);
% plotconfusion(mdl.Y,predict(mdl,mdl.X));