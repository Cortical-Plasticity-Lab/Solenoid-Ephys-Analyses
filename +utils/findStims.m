function [iStim,F] = findStims(stimFolder)
%FINDSTIMS Return stimulation indices based on all STIM files
%
%  [iStim,F] = utils.findStims(stimFolder);
%
% Inputs
%  stimFolder  - e.g. 'P:\Rat\...\R19-226_2019_11_05_1_Digital\STIM_DATA'
%
% Output
%  iStim       - Cell array for each STIM file, corresponding to elements
%                 of `F`. Indices indicate samples of ICMS delivery
%
% See also: Contents

F = dir(fullfile(stimFolder,'*STIM*.mat'));
iStim = cell(size(F));
for iF = 1:numel(F)
   data = getfield(load(fullfile(F(iF).folder,F(iF).name)),'data');
   iStim{iF} = find(data~=0);
end

end