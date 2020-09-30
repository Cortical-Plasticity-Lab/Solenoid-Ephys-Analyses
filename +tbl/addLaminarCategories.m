function [T,L] = addLaminarCategories(T,varargin)
%ADDLAMINARCATEGORIES Adds categorical variable `Lamina` based on depth/area
%
%  T = tbl.addLaminarCategories(T);
%  [T,L] = tbl.addLaminarCategories(T,'Name',value,...);
%
% Inputs
%  T        - Main database table with `Spikes` and `LFP` data responses
%  varargin - (Optional) 'Name',value input argument pairs.
%
% Output
%  T        - Updated database table with new variable: `Lamina`
%              -> Depends on combination of channel Depth and Area
%  L        - Lamina categorization information table
%
% See also: Contents

pars = struct;
pars.Area = ["RFA","S1"];
pars.CategoryVars = {1:5,...
   ["Layer I", "Layer II/III", "Layer IV", "Layer V", "Layer VI"]};
pars.LaminaFile = 'Lamina-Info.xlsx';

fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx) == 1
      pars.(fn{idx}) = varargin{iV+1};
   end
end


warning('off','MATLAB:table:ModifiedAndSavedVarnames');
L = readtable(pars.LaminaFile);
warning('on','MATLAB:table:ModifiedAndSavedVarnames');
L.Properties.VariableNames = ["Area","Lamina","UB","LB"];
L.Properties.VariableUnits = {'','','\mum','\mum'};

% Initialize categories for output variable
T.Lamina = categorical(nan(size(T,1),1),pars.CategoryVars{:});
L.Lamina = categorical(L.Lamina);

for iA = 1:numel(pars.Area)
   iArea = T.Area==pars.Area(iA);
   l = L(L.Area==pars.Area(iA),:);
   for iL = 1:size(l,1)
      idx = iArea & ...
         (l.UB(iL) < T.Depth) & ...
         (T.Depth <= l.LB(iL));
      T.Lamina(idx) = repmat(l.Lamina(iL),sum(idx),1);
   end
end

T = movevars(T,'Lamina','before','ChannelID');

end