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

G = (1:size(T,1))';
tLFP = T.Properties.UserData.t.LFP;
fprintf(1,'Computing individual trial time-to-minima...');
T.ElectrodeID = categorical(strcat(string(T.SurgID),"-",string(T.ChannelID)));
T.TrialType = categorical(string(T.Type));
% tZero == tOffset; if we use this with respect to some offset, we are
% interested in finding the (minima) that occurred after that offset.
T.tLFPMin = splitapply(@(LFP,tZero)tbl.est.tLFPavgMin(LFP,tLFP,'ZeroLFPBeforeThisTimeMS',tZero),...
   T.LFP,tOffset,G) - tOffset;
T.Properties.VariableUnits{'tLFPMin'} = 'ms';
fprintf(1,'complete (%5.2f sec)\n',toc);

end