function T = addLV(T)
%ADDLV Add lesion volume information to main table
%
%    T = tbl.addLV(T);
%   [T,V] = tbl.addLaminarCategories(T,'Name',value,...);
% Inputs
%  T           - Table of spike and LFP data with each row as an individual
%                 trial from the solenoid experiment
%
% Output
%  T           - Table without low-spiking channels in each block
%  V           - Table with lesion volume information
%
% See also: tbl, addLaminarCategories.m, Contents

pars = struct;
pars.LesionVolumeFile = 'Lesion-Info.xlsx';

V = readtable(pars.LesionVolumeFile);
V.Properties.VariableNames = {'SurgID','Lesion_Volume','LV_Category'};
V.Properties.VariableUnits = {'','mm^3',''};

V.LV_Category = categorical(V.LV_Category);
T.Lesion_Volume = [zeros(size(T,1),1)];

for iS = 1:numel(V.SurgID)
   iSurg = (T.SurgID == V.SurgID(iS));
   T.Lesion_Volume(iSurg) = V.Lesion_Volume(iS);
end

T = T(:,[end, 1:(end-1)]);

T.Properties.VariableUnits{'Lesion_Volume'} = V.Properties.VariableUnits{2};
end