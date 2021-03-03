function iRow = selector2mask(C,T)
%SELECTOR2MASK Return mask based on selector struct and data table
%
%  iRow = utils.selector2mask(C,T);
%
% Inputs
%  C - "Selector" struct (see utils.getSelector)
%  T - Data table to apply selector to. Must have variables described in
%        the struct.
%  
% Output
%  iRow - Logical vector to select rows
%
% See also: Contents

iRow = false(size(T,1),1);
for iC = 1:numel(C)
   % Get logical AND (arrays within each field of element in `C`)
   iThis = true(size(T,1),1);   
   for ii = 1:numel(C(iC).Variable)
      iThis = iThis & T.(C(iC).Variable(ii)) == C(iC).Value(ii);
   end
   % Get logical OR (each unique element in struct array `C`)
   iRow = iRow | iThis;
end

end