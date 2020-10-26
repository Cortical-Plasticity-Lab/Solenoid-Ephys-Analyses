function TID = getSingleton(T,TID,name,G)
%GETSINGLETON Update table with singleton value from `T`
%
%  TID = utils.getSingleton(T,TID,name,G);
%
% Inputs
%  T - Main data table
%  TID - Smaller subtable that matches indexing in `G`
%  name - Name of variables to use singleton element from T
%  G   - Group indexing variable
%
% Output
%  TID - Updated subtable
%
% See also: Contents

if iscell(name)
   for ii = 1:numel(name)
      TID = utils.getSingleton(T,TID,name{ii},G);
   end
   return;
end

if ismember(name,T.Properties.VariableNames)
   TID.(name) = splitapply(@(x)x(1),T.(name),G);
else
   warning('%s is not a member of table variables list. TID not updated.',name);
end

end