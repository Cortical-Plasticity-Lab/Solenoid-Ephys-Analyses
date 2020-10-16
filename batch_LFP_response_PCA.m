%BATCH_LFP_RESPONSE_PCA Script organizing PCA of LFP responses

%% Load data
clc;
clearvars -except T

if exist('T','var')==0
%    T = getfield(load('P:\Rat\BilateralReach\Solenoid Experiments\Solenoid-Table__5-ms-MM.mat','T'),'T');
   T = getfield(load('Solenoid-Table_5-ms_excluded_ipsi.mat','T'),'T');
end

%% Get principal components as channel combinations
% Split up data
[G,TID] = findgroups(T(:,{'BlockID','Type'}));

% Get principal components and corresponding channel identifiers etc
