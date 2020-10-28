%BATCH_FIG3 Batch script to run code associated with generating Figure 3

%% Load data
clc;
clearvars -except T C

if exist('T','var')==0
%    T = getfield(load('P:\Rat\BilateralReach\Solenoid Experiments\Solenoid-Table__5-ms-MM.mat','T'),'T');
   T = getfield(load('Solenoid-Table_5-ms_excluded_ipsi.mat','T'),'T');
end

F = Fig3.groupDataSuppressICMS(T,'LFP');