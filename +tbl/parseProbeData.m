function T = parseProbeData(T,probeFile)
%PARSEPROBEDATA Parse data about probes from file Probe-info.xlsx
%
%  T = tbl.parseProbeData(T);
%  T = tbl.parseProbeData(T,probeFile);
%
% Inputs
%  T     - Table where each row is a single trial for a single channel
%           (main database with variables 'Spikes' and 'LFP' as outputs)
%  probeFile - (Optional) char array or string that is the filename for the
%                 probe-info spreadsheet, if it is not located in the
%                 Project folder immediately.
%
% Output
%  T     - Same as input table but with data added (specifically, Area)

if nargin < 2
   probeFile = cfg.default('site_location_table');
end

P = readtable(probeFile);
P.Probe = categorical(P.Probe);
P.Area = categorical(P.Area);
P.BlockID = categorical(P.BlockID);

T = outerjoin(T,P,'Type','Left',...
   'MergeKeys',true,...
   'Keys',{'BlockID','Probe'},...
   'LeftVariables',setdiff(T.Properties.VariableNames,'Area'),...
   'RightVariables',{'Area'});
T.Properties.RowNames = T.ID;
if ismember('RowID',T.Properties.VariableNames)
   T.RowID = [];
end

end