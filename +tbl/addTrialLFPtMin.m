function T = addTrialLFPtMin(T,tOffset)
%ADDTRIALLFPTMIN Add LFP time-to-min as variable to main data table
%
%  T = tbl.addTrialLFPtMin(T);
%  T = tbl.addTrialLFPtMin(T,tOffset);
%
% Inputs
%  T - Main database table
%  tOffset - Vector of offsets. If not specified, then this is a vector of
%              zeros.
%
% Output
%  T - Same table, with added variable `tLFPMin`
%
% See also: Contents, tbl, tbl.stats

if nargin < 2
   tOffset = zeros(size(T,1),1);
else
   tOffset(isnan(tOffset) | isinf(tOffset)) = 0;   
end

tic;
fprintf(1,'Adding Lamina, ElectrodeID, Solenoid_ICMS_Delay, and Solenoid_Dwell variables...');  
T = tbl.addLaminarCategories(T);
T.TrialType = string(T.Type);
T.ElectrodeID = strcat(string(T.SurgID),"-",string(T.ChannelID));
T.Solenoid_ICMS_Delay = (T.Solenoid_Onset - T.ICMS_Onset).*1000;
T.Solenoid_ICMS_Delay(isinf(T.Solenoid_ICMS_Delay) | isnan(T.Solenoid_ICMS_Delay)) = 0;
T.Properties.VariableUnits{'Solenoid_ICMS_Delay'} = 'ms';
fprintf(1,'complete (%5.2f sec)\n',toc);

tic;
G = (1:size(T,1))';
tLFP = T.Properties.UserData.t.LFP;
fprintf(1,'Computing individual trial time-to-LFP-minima...');

T.Solenoid_Dwell = T.Solenoid_Offset - T.Solenoid_Onset;
T.Properties.VariableUnits{'Solenoid_Dwell'} = 'sec';
% tZero == tOffset; if we use this with respect to some offset, we are
% interested in finding the (minima) that occurred after that offset.
T.tLFPMin = splitapply(@(LFP,tZero)tbl.est.tLFPavgMin(LFP,tLFP,'ZeroLFPBeforeThisTimeMS',tZero),...
   T.LFP,tOffset,G) - tOffset;
T.Properties.VariableUnits{'tLFPMin'} = 'ms';
fprintf(1,'complete (%5.2f sec)\n',toc);


end