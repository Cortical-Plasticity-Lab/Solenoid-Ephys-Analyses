function exclude = requireAnyResponse(N,ID,Type)
%REQUIREANYRESPONSE Requires observation by "ID" to have --any-- response at least once across each combination of ID and Type
%
%  exclude = tbl.requireAnyResponse(N,ID,Type);
%
% Inputs
%  N     - Counts of responses
%  ID    - ID for grouping observations (e.g. ElectrodeID)
%  Type  - Type for splitting observations (e.g. "Solenoid" "ICMS" "Solenoid + ICMS")
%           -> Type, ID, N should all be vectors with same number of
%               elements.
%
% Output
%  exclude - Logical vector size of N with true values indicating which
%              observations to exclude.
%
% See also: tbl, run_stats.m

T = table(ID,Type,N);

[G,TID] = findgroups(T(:,'ID'));

TID.N = splitapply(@(x)sum(x),T.N,G);
TID.exclude = TID.N == 0;

[T,iOrig] = outerjoin(T,TID,...
   'Keys',{'ID'},...
   'Type','left',...
   'LeftVariables',{'ID','Type','N'},...
   'RightVariables',{'exclude'});

[~,iSort] = sort(iOrig,'ascend');
T = T(iSort,:);

exclude = T.exclude;

end