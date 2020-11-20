function str = parseDataDescriptor(T,iRow)
%PARSEDATADESCRIPTOR Parses descriptor of data point based on row index and variables available in input data table
%
% Inputs
%  T    - Data table
%  iRow - Indexing scalar or vector to indicate which rows to include
%
% Output
%  str  - Strings corresponding to the rows for data to be labeled
%
% See also: Contents, tbl, tbl.gfx, tbl.gfx.makeMultiPeakExamplePETH

v = T.Properties.VariableNames;
if all(ismember({'ElectrodeID','Area','Lamina','Type'},v))
   str = strcat(string(T.ElectrodeID(iRow))," (",string(T.Area(iRow)),"|",string(T.Lamina(iRow)),"): ",string(T.Type(iRow)));
elseif all(ismember({'ElectrodeID','Area','Type'},v))
   str = strcat(string(T.ElectrodeID(iRow))," (",string(T.Area(iRow)),"): ",string(T.Type(iRow)));
elseif all(ismember({'Area','Lamina','Type'},v))
   str = strcat("(",string(T.Area(iRow)),"|",string(T.Lamina(iRow)),"): ",string(T.Type(iRow)));
elseif all(ismember({'ElectrodeID','Area','Lamina'},v))
   str = strcat(string(T.ElectrodeID(iRow))," (",string(T.Area(iRow)),"|",string(T.Lamina(iRow)),")");
elseif all(ismember({'Area','Type'},v))
   str = strcat("(",string(T.Area(iRow)),"): ",string(T.Type(iRow)));
else
   if islogical(iRow)
      str = strings(sum(iRow),1);
   else
      str = strings(numel(Row),1);
   end
end

end