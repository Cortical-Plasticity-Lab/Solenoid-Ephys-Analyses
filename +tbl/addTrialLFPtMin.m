function T = addTrialLFPtMin(T)
%ADDTRIALLFPTMIN Add LFP time-to-min as variable to main data table
%
%  T = tbl.addTrialLFPtMin(T);
%
% Inputs
%  T - Main database table
%
% Output
%  T - Same table, with added variable `tLFPMin`
%
% See also: Contents, tbl, tbl.stats

tic;

G = (1:size(T,1))';
tLFP = T.Properties.UserData.t.LFP;
fprintf(1,'Computing indiivdual trial time-to-minima...');
T.tLFPMin = splitapply(@(LFP)tbl.est.tLFPavgMin(LFP,tLFP),T.LFP,G);
T.Properties.VariableUnits{'tLFPMin'} = 'ms';
fprintf(1,'complete (%5.2f sec)\n',toc);

end