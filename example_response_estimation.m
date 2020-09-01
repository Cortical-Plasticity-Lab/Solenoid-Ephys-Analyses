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

%% Display figure of minima distribution, by area, for Solenoid strikes only
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

%% Illustrating intentional errors in prior code
% So now we have a way to plot and compare time to LFP peak minima. 
% 
% Note 4:
% I could have made Figures.CompareTimeToLFPMinima(C):
%
%  fig_min = Figures.CompareTimeToLFPpeak(C,'LFP_tMin');
%  fig_max = Figures.CompareTimeToLFPpeak(C,'LFP_tMax');
%
% That way I could have generalized the function so that it handled both
% "minima" and "maxima" without having to write the same code twice. It
% would only require that I code a second input argument, specifying the
% table variable to be used in the output graphic where histogram or
% ksdensity is called in the "CompareTimeToLFPMinima" version.
%
% Note 5:
% Something else is wrong: the Solenoid strike does not always occur at
% experimental trial time "zero" -- sometimes it is lagged relative to
% "trial" onset by some amount (so that ICMS could be delivered prior to
% solenoid strike, for example). The code to compute time-to-peak only uses
% the times with reference to the trial times, not with respect to the
% stimulus, since on any given trial the stimulus might be one or multiple
% different sources. We should redo it, specifying a reference time. We can
% easily include this as an additional <'Name',value> parameter argument in
% (new) `tLFPpeak`, which as previously pointed out, can be used to
% flexibly compute min or max depending on an additional input argument.

% Recompute values of minima
tLFP = C.Properties.UserData.t.LFP;
fcn = @(LFP_mean,Solenoid_Onset)tbl.est.tLFPpeak(LFP_mean,Solenoid_Onset,tLFP,'min');
inputVars = {'LFP_mean','Solenoid_Onset'}; % Now we have to specify 2 args: anything that must be "matched" on a per-row basis when splitting up the table has to be done this way
outputVar = 'LFP_tMin';  
C = tbl.stats.estimateChannelResponse(C,fcn,inputVars,outputVar); % ~1 sec

% We should make sure it's understood what LFP_tMin refers to
C.Properties.VariableUnits{'LFP_tMin'} = 'ms'; % milliseconds
desc = ['Minimum average LFP time with respect to Solenoid Onset' newline ...
    '(only valid for Solenoid-Only trials!)'];
C.Properties.VariableDescriptions{'LFP_tMin'} = desc;
   

% Setting VariableDescriptions when we open the Table in the Workspace
% variables list to inspect its properties, when we click the arrow next to
% the variable name in the corresponding column for LFP_tMin, we will now
% see this note included with the table.

% Fortunately, since we specified the other graphic function, we can
% correct the mistake easily, using the fixed table:
fig = Figures.CompareTimeToLFPMinima(C);
pause(1.5);
delete(fig); % Using figure handle we can programmatically close/save figs

% Looks like that doesn't even change the figure at all; we could have
% avoided this by simply looking at distribution of Solenoid Onset times
% for Solenoid-Only trials:
[fig,ax] = utils.getFigAx([],...
   sprintf('Solenoid Onset Distribution (%s)',...
   C.Properties.VariableUnits{'Solenoid_Onset'}));
histogram(ax,C.Solenoid_Onset(C.Type=="Solenoid"));
pause(2.5);
delete(fig);

% Whoops, solenoid onset times are in seconds, which is the problem here.
% We could correct it in the table, or alternatively we can handle it this
% way:
fcn = @(LFP_mean,Solenoid_Onset)tbl.est.tLFPpeak(LFP_mean,Solenoid_Onset.*1e3,tLFP,'min');
% Now solenoid onset will be multiplied by 1000 prior to estimation of
% minima times, which should resolve the issue.
C = tbl.stats.estimateChannelResponse(C,fcn,inputVars,outputVar,...
   'OutputVariableUnits','ms','OutputVariableDescription',desc); % ~1 sec
fig = Figures.CompareTimeToLFPMinima(C); % And create corrected figure
figName = fullfile('figures','LFP Minima Comparison');
savefig(fig,[figName '.fig']);
saveas(fig,[figName '.png']);
delete(fig);