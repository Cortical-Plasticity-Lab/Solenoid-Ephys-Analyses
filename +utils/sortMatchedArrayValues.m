function C = sortMatchedArrayValues(C,sortVar,varargin)
%SORTMATCHEDARRAYVALUES Sort matched table array values from reference array (in that table)
%
%  C = utils.sortMatchedArrayValues(C,sortVar,'matchedVar1',...,'matchedVark');
%
% Inputs
%  C - Data table where some of the variables are arrays (multiple columns)
%  sortVar - Name of "reference" variable that is used to sort. Sort orders
%              with largest values in `sortVar` in the left-most column,
%              and moves any NaN values to the right of any non-NaN values.
%  varargin - Any number of "matched" variables with the same number of
%              columns, which should be sorted according to the sorting
%              applied to data in C.(sortVar)
%
% Output
%  C - Same as input data table, with sorted values.
% 
% See also: Contents, tbl, tbl.peak2rows, new_analysis.m, analyze, 
%              analyze.detectAverageEvokedSpikePeaks

nRow = size(C,1);
nCol = size(C.(sortVar),2);

[C.(sortVar),C.sortRank] = sort(C.(sortVar),2,'descend','MissingPlacement','last');
idx = mat2cell(C.sortRank,ones(1,nRow),nCol);

for iV = 1:numel(varargin)
   C.(varargin{iV}) = mat2cell(C.(varargin{iV}),ones(1,nRow),nCol);
   C.(varargin{iV}) = cell2mat(...
      cellfun(@(x,k)x(k),C.(varargin{iV}),idx,...
      'UniformOutput',false));
end

end