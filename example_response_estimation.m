%EXAMPLE_RESPONSE_ESTIMATION Example script to show response estimate workflow using main database table
clearvars -except T C
clc;

% Define a function handle to aggregate LFP data at the Channel level
fcn = @(X){nanmean(X,1)}; % Returns trial-average time-series (as a cell)
inputVars = {'LFP'}; % Will use the 'LFP' variable in T
outputVar = 'LFP_mean'; % Output variable name

% Rows of this table represent unique Channel/Block/Trial Type combinations
C = tbl.stats.estimateChannelResponse(T,fcn,inputVars,outputVar); % ~15 sec

% Note 1:
% This function can be repeated on the Channel-aggregated table (as shown 
% next), as that table contains all the information that is needed to group 
% by Channels! So let's say we want to do processing on trial averages, 
% we can then re-use this function with a different "small" function handle
% to be applied to the averages.
%
% Note 2:
% Don't need to redefine new variables each time, could just give them
% directly to the function as arguments, I'm just doing this for clarity.
fcn = @(LFP_mean)tbl.est.tLFPavgMin(LFP_mean,C.Properties.UserData.t.LFP);
inputVars = 'LFP_mean';
outputVar = 'LFP_tMin';
C = tbl.stats.estimateChannelResponse(C,fcn,inputVars,outputVar); % ~4 sec
figure; histogram(C.LFP_tMin); title('LFP Time-to-Minimum (ms)');

% Note that something went wrong with our algorithm: there is a (very)
% negative peak, which should be impossible! 
%  -> Let me know if you need help figuring out why that happened.