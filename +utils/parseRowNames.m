function rowNames = parseRowNames(T)
%PARSEROWNAMES Parse row names depending on variables present in data table
%
%  rowNames = utils.parseRowNames(T);
%
% Inputs
%  T - Data table from various workflows in this project
%
% Output
%  rowNames - String array of names for each row.
%
% See also: Contents, new_analysis.m, run_stats.m,
%                     tbl, tbl.gfx, tbl.gfx.makeMultiPeakExamplePETH

v = T.Properties.VariableNames;
if all(ismember({'SurgID','BlockIndex','ChannelID','Type','Area'},v))
   rowNames = strcat(string(T.SurgID),"-",num2str(T.BlockIndex),"::",T.ChannelID,"-",strrep(string(T.Type)," ",""),"::",string(T.Area));
elseif all(ismember({'BlockID','ChannelID','Type','Area'},v))
   rowNames = strcat(string(T.BlockID),"::",T.ChannelID,"-",strrep(string(T.Type)," ",""),"::",string(T.Area));
elseif all(ismember({'SurgID','ChannelID','Area'},v))
   rowNames = strcat(string(T.SurgID),"::",T.ChannelID,"::",string(T.Area));
elseif all(ismember({'BlockID','ChannelID'},v))
   rowNames = strcat(string(T.BlockID),"::",T.ChannelID); 
else
   id = 1:size(T,1);
   rowNames = strcat("RowID::",num2str(id,'%04d'));
end
   
   
end