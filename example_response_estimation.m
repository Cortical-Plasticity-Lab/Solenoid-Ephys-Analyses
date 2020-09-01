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
ax = utils.formatDefaultAxes(subplot(1,2,1),'Parent',fig,'XLim',[30 250]); % Helper to apply MM-preferred axes properties
histogram(ax,C.LFP_tMin(C.Type=="Solenoid" & C.Area=="S1"),30:10:250,'FaceColor',cfg.gfx('Color_S1'),'EdgeColor','none','Normalization','pdf');
set(findobj(ax.Children','Type','histogram'),'DisplayName','Observed Distribution');
ksdensity(ax,C.LFP_tMin(C.Type=="Solenoid" & C.Area=="S1"),'Function','pdf','kernel','Epanechnikov'); % Epanechnikov: kernel is optimal with respect to minimizing mean-square error
set(findobj(ax.Children,'Type','line'),'LineWidth',2.5,'Color','k','LineStyle',':','DisplayName','Smoothed Distribution Estimate');
utils.formatDefaultLabel([title(ax,'S1');xlabel(ax,'Time (ms)');ylabel(ax,'Count')],'Color',cfg.gfx('Color_S1'));
utils.addLegendToAxes(ax); % Add formatted axes
ax = utils.formatDefaultAxes(subplot(1,2,2),'Parent',fig,'XLim',[30 250],'YLim',ax.YLim); % Give it the same y-limits as the S1 axes
histogram(ax,C.LFP_tMin(C.Type=="Solenoid" & C.Area=="RFA"),30:10:250,'FaceColor',cfg.gfx('Color_RFA'),'EdgeColor','none','Normalization','pdf');
set(findobj(ax.Children','Type','histogram'),'DisplayName','Observed Distribution');
ksdensity(ax,C.LFP_tMin(C.Type=="Solenoid" & C.Area=="RFA"),'Function','pdf','kernel','Epanechnikov');  % Epanechnikov: kernel is optimal with respect to minimizing mean-square error
set(findobj(ax.Children,'Type','line'),'LineWidth',2.5,'Color','k','LineStyle',':','DisplayName','Smoothed Distribution Estimate');
utils.addLegendToAxes(ax); % Add formatted axes
utils.formatDefaultLabel([title(ax,'RFA');xlabel(ax,'Time (ms)');ylabel(ax,'Count')],'Color',cfg.gfx('Color_RFA'));

% Note 3: 
% See code in Figures.CompareTimeToLFPMinima, which is the same as
% above. This is an example of (my) standard workflow: iterate and develop
% in "test" scripts that organize everything (you will lose track of it if
% done in the Command Window otherwise); then, as you make figures or other
% "compartmentalized" elements, move them into functions so that you can
% recall them easier in the future and so that they are clearly categorized
% with what associated (manuscript-related) endpoint they go with. The
% Contents.m in +Figures should give a summary of what "endpoint" figures
% there are as they relate to the repository experiment.

% Same result as previous steps:
% C = tbl.stats.estimateChannelResponse(C,fcn,inputVars,outputVar); % ~4 sec
% fig = Figures.CompareTimeToLFPMinima(C);