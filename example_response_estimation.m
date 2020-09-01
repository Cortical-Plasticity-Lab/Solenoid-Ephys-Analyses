%EXAMPLE_RESPONSE_ESTIMATION Example script to show response estimate workflow using main database table
clearvars -except T C
clc;

%% Estimate cross-trial channel averages, by trial type and recording
% Define a function handle to aggregate LFP data at the Channel level
fcn = @(X){nanmean(X,1)}; % Returns trial-average time-series (as a cell)
inputVars = {'LFP'}; % Will use the 'LFP' variable in T
outputVar = 'LFP_mean'; % Output variable name

% Rows of this table represent unique Channel/Block/Trial Type combinations
C = tbl.stats.estimateChannelResponse(T,fcn,inputVars,outputVar); % ~15 sec

%% Estimate time-to-minimum
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
fig = utils.formatDefaultFigure(figure,'Name','Distributions of LFP Time-to-Minima (ms)'); 
ax = utils.formatDefaultAxes(subplot(1,2,1),'Parent',fig); % Helper to apply MM-preferred axes properties
histogram(ax,C.LFP_tMin(C.Type=="Solenoid" & C.Area=="S1"),30:10:250);
utils.formatDefaultLabel([title(ax,'S1');xlabel(ax,'Time (ms)');ylabel(ax,'Count')]);
ax = utils.formatDefaultAxes(subplot(1,2,2),'Parent',fig); % Helper to apply MM-preferred axes properties
histogram(ax,C.LFP_tMin(C.Type=="Solenoid" & C.Area=="RFA"),30:10:250);
utils.formatDefaultLabel([title(ax,'RFA');xlabel(ax,'Time (ms)');ylabel(ax,'Count')]);