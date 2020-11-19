function T2 = pivotRows(T1,varargin)
%PIVOTROWS Pivot rows of each corresponding variable in `T1` to produce `T2`
%
%  T2 = utils.pivotRows(T1,'var1',...,'vark');
%
% Inputs
%  T1 - Original data table with some variable or variables that are arrays
%        and which are to be organized so that new rows
%
% Output
%  T2 - New "pivoted" table
%        -> Variables are same as T1, with the addition of a new variable
%           `Array_Column`, which indicates which column of the array a
%           particular row corresponds to. 
%
% See also: Contents, tbl.peaks2rows

if numel(varargin) == 0
   T2 = T1;
   warning('No rows to pivot! Returning original data table.');
   return;
end

nRow = size(T1,1);
nCol = size(T1.(varargin{1}),2);

T2 = T1(:,setdiff(T1.Properties.VariableNames,varargin));
T2.Properties.RowNames = {};
T2 = repmat(T2,nCol,1);

vec = 1:nRow;
T2.Array_Column = nan(nRow*nCol,1);
if isempty(T1.Properties.RowNames)
   for ii = 1:nCol
      T2.Array_Column(vec) = ones(nRow,1).*ii;
      vec = vec + nRow;
   end
else
   rowNames = strings(nRow*nCol,1);
   for ii = 1:nCol
      rowNames(vec) = strcat(string(T1.Properties.RowNames),"-",num2str(ii));
      T2.Array_Column(vec) = ones(nRow,1).*ii;
      vec = vec + nRow;
   end
   T2.Properties.RowNames = rowNames;
end

for iV = 1:numel(varargin)
   T2.(varargin{iV}) = T1.(varargin{iV})(:);
end

end