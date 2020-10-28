%BATCH_LFP_RESPONSE_PCA Script organizing PCA of LFP responses

%% Load data
clc;
clearvars -except T C

if exist('T','var')==0
%    T = getfield(load('P:\Rat\BilateralReach\Solenoid Experiments\Solenoid-Table__5-ms-MM.mat','T'),'T');
   T = getfield(load('Solenoid-Table_5-ms_excluded_ipsi.mat','T'),'T');
end

%% Create "Channels" table
if exist('C','var')==0
   C = tbl.stats.estimateChannelResponse(T,@(X){rms(X,1)},{'LFP'},'LFP');
end

%% Get principal components as channel combinations
% Split up data
T = tbl.stats.addSolenoidLFPbetas(T,C,3);

