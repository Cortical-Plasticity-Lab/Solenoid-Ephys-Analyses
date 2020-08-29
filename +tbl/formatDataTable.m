function T = formatDataTable(T)
%FORMATDATATABLE Get data table into correct format with largest grouping variables on the left, and dependent variables on the right
%
%  T = tbl.formatDataTable(T);
%
% Inputs
%  T - Main database table in which rows are individual trials for
%        individual channels.
%
% Output
%  T - Same table, but with rows re-ordered and variable units added where
%        needed.
%
% See also: tbl, tbl.parseBlockID, tbl.parseProbeData

T.Properties.RowNames = T.ID;
if ismember('RowID',T.Properties.VariableNames)
   T.RowID = [];
end

T = movevars(T,{'LFP','Spikes'},'after',size(T,2));
T = movevars(T,{'ID','GroupID','SurgID','AnimalID','BlockID','BlockIndex','Type','Area','ChannelID'},'before',1);
T = movevars(T,{'ML','Depth'},'after','AP');
T.Properties.VariableUnits{'ML'} = 'microns';
T.Properties.VariableUnits{'AP'} = 'microns';
T.Properties.VariableUnits{'Depth'} = 'microns';
T = movevars(T,{'Stim_Ch','ICMS_Channel','ICMS_Onset'},'before','Date');
T.Properties.VariableUnits{'ICMS_Onset'} = 'sec';
T = movevars(T,{'Hemisphere','Solenoid_Paw','Solenoid_Target','Solenoid_Onset','Solenoid_Offset'},'before','Gross_Attempts');
T = movevars(T,{'coeff','p','Stim_Dist','Impedance'},'before','Gross_Attempts');
T.Properties.VariableUnits{'coeff'} = 'improvement/day';
T.Properties.VariableDescriptions{'coeff'} = 'Regression coefficient for recovery, fit for this animal based on pellet retrievals';
T.Properties.VariableUnits{'p'} = 'probability';
T.Properties.VariableDescriptions{'p'} = 'Probability that coefficient for recovery is non-zero';
T.Properties.VariableUnits{'Stim_DV'} = 'mm';
T.Properties.VariableUnits{'Stim_Dist'} = 'microns';
T.Properties.VariableDescriptions{'Stim_Dist'} = 'This is distance from the Stim Site, but should only be used for probes on same array as stimulus';
stim_p = categorical(extractBefore(T.Stim_Ch,2),["A","B"],{'A','B'});
T.Stim_Dist(T.Probe~=stim_p) = inf;
T.Properties.VariableUnits{'Solenoid_Onset'} = 'sec';
T.Properties.VariableUnits{'Solenoid_Offset'} = 'sec';
T.Properties.VariableUnits{'Spikes'} = 'Spikes';
T.Properties.VariableDescriptions{'Spikes'} = 'Binned spike counts (see UserData `t` field for corresponding bin center times, which are in seconds)';
T.Properties.VariableUnits{'LFP'} = '\muV';
T.Properties.VariableDescriptions{'LFP'} = 'Average decimated local field potential (see UserData `t` field for corresponding bin center times, which are in milliseconds)';
T.Properties.VariableUnits{'Time'} = 'sec';
T.Properties.VariableDescriptions{'Time'} = 'Time, relative to onset of recording';

T.Stim_Ch = strrep(T.Stim_Ch,'-','');
T.Properties.UserData.SolenoidDelay = 4; %ms
T.Properties.UserData.SolenoidDelayUnits = 'ms';
end