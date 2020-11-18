function [G,TID] = export_table(T,groupVars,sheet,splitFcn,splitOut,splitIn)
%EXPORT_TABLE Shortcut to export to "aggregator" table.
%
%  [G,TID] = tbl.export_table(T,groupVars,sheet);
%  [G,TID] = tbl.export_table(T,groupVars,sheet,splitFcn,splitOut,splitIn);
%
% Inputs
%  T         - Table to export
%  groupVars - Grouping variables to collapse table
%  sheet     - Name of sheet to write to
%
%  (Optional)
%  splitFcn  - splitapply workflow function 
%  splitOut  - Table variable in TID that is output by splitFcn
%  splitIn   - Table variable(s) to use for inputs to splitFcn
%
% Output
%  G         - Grouping index vector for aggregating TID
%  TID       - Corresponding groupings of G (this is written to the file)
%
% See also: tbl

if nargin < 3
   error('Must provide at least three input arguments.');
end

[G,TID] = findgroups(T(:,groupVars));
if nargin > 3
   if nargin < 6
      error('Must provide `splitFcn`, `splitOut`, and `splitIn` args.');
   end
   TID.(splitOut) = splitapply(...
      @(varargin)splitFcn(varargin{:}),...
      T(:,splitIn),G);
end

writetable(TID,'Tables.xlsx','Sheet',sheet);

end