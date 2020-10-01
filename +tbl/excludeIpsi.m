function T = excludeIpsi(T,exclBl)
%EXCLUDEIPSI Exclude trials on the ipsilateral side from dataset 
%
%  t = tbl.excludeIpsi(T,exclBl,);
%  t = tbl.excludeIpsi(T,exclBl,'Name',value,...);
%
% Inputs
%  T           - Table of spike and LFP data with each row as an individual
%                 trial from the solenoid experiment (Solenoid-Table_5-ms)
%  exclBl      - Cell array with ipsilateral BlockID names
%  
% Output
%  T           - Same table but with ipsilateral trials removed

% See also: tbl, tbl.formatDataTable 
 
initialVars = who;
numTrials = numel(exclBl);
for i = 1:numTrials
    bl = exclBl{i};
    exc = (T.BlockID == bl);
    T(exc,:)= [];
end
clearvars('-except',initialVars{:})
save('Solenoid-Table_5-ms_excluded_ipsi','T','-v7.3');
end