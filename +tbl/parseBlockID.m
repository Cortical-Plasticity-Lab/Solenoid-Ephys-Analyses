function T = parseBlockID(T)
%PARSEBLOCKID Parse block ID metadata as variables
%
%  T = tbl.parseBlockID(T);
%
% Inputs
%  T - Full database table exported from `solRat.makeTables`
%
% Output
%  T - Same table, but with parsed fields from metadata in BlockID variable
%
% See also: tbl, tbl.gfx, tbl.stats, solRat, solRat/makeTables

b = string(T.BlockID);
T.BlockIndex = str2double(extractAfter(b,19));


T.SurgID = categorical(T.SurgID);
T.AnimalID = categorical(T.AnimalID);
T.Group = categorical(T.Group);
T.Properties.VariableNames{'Group'} = 'GroupID';


T.ChannelID = string(strrep(T.ChannelID,'-',''));

yyyy = extractBetween(b,9,12);
mm = extractBetween(b,14,15);
dd = extractBetween(b,17,18);
T.Date = strcat(yyyy,'-',mm,'-',dd);

T = movevars(T,{'BlockIndex','ChannelID'},'before','Gross_Attempts');
T.ID = strcat(string(T.SurgID),"_B",num2str(T.BlockIndex,'%02d'),"_C",T.ChannelID,"_T",num2str(T.Number,'%03d'));
T = movevars(T,'ID','before',1);
T.Properties.RowNames = T.ID;

end