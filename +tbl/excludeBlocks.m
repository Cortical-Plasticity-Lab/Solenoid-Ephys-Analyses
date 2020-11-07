function T = excludeBlocks(T)
%EXCLUDEBLOCKS Exclude blocks from dataset 
%
%  T = tbl.excludeBlocks(T);
%  T = tbl.excludeBlocks(T,'Name',value,...);
%
% Inputs
%  T           - Table of spike and LFP data with each row as an individual
%                 trial from the solenoid experiment (Solenoid-Table_5-ms)
%  exclBl      - Cell array with BlockID names
%  
% Output
%  T           - Same table but with blocks with ipsilateral trials and S1 stimulation removed

% See also: tbl, tbl.formatDataTable 
 
initialVars = who;
exclIpsi = {'R19-234_2019_11_07_7','R19-232_2019_11_07_4'}; % Ipsilateral blocks
exclS1 = {'R19-234_2019_11_07_1','R19-234_2019_11_07_2','R19-234_2019_11_07_3',...
    'R19-232_2019_11_07_3','R19-231_2019_11_06_5','R19-230_2019_11_06_3','R19-230_2019_11_06_4',...
    'R19-227_2019_11_05_5','R19-227_2019_11_05_6'}; % S1 stimulation blocks
excl = [exclIpsi,exclS1];
numTrials = numel(excl);
for i = 1:numTrials
    bl = excl{i};
    exc = (T.BlockID == bl);
    T(exc,:)= [];
end
clearvars('-except',initialVars{:})
save('Solenoid-Table_5-ms_excluded_ipsi','T','-v7.3');
end