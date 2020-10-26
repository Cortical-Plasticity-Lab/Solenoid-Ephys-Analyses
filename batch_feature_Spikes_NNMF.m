%BATCH_FEATURE_SPIKES_NNMF Apply NNMF to spike data

clc;
clearvars -except T F C

if exist('T','var')==0
%    T = getfield(load('P:\Rat\BilateralReach\Solenoid Experiments\Solenoid-Table__5-ms-MM.mat','T'),'T');
   T = getfield(load('Solenoid-Table_5-ms_excluded_ipsi.mat','T'),'T');
end

% Create reduced database
if exist('F','var')==0
   F = utils.reduceData(T);
end

% Create "Channels" table
if exist('C','var')==0
   C = tbl.stats.estimateChannelResponse(F,@(X){mean(X,1)},{'Spikes'},'Spikes');
end

%% Create visualization of factors
analyze.factors.meanPETH(C);

%% Create visualization of factors from only Solenoid strikes
analyze.factors.meanPETH(C,"Solenoid");

%% Create visualization of factors from only ICMS stimuli
analyze.factors.meanPETH(C,"ICMS");

%% Create visualization of factors from only Solenoid + ICMS Stimuli 
analyze.factors.meanPETH(C,"Solenoid + ICMS");