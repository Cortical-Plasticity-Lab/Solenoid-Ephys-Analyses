function BinomialSize = findMaxResponse(N,ID,Type)
%FINDMAXRESPONSE Get BinomialSize using maximum number of responses for "ID" by "Type"
%
%  BinomialSize = tbl.findMaxResponse(N,ID,Type);
%
% Inputs
%  N     - Counts of responses
%  ID    - ID for grouping observations (e.g. ElectrodeID)
%  Type  - Type for splitting observations (e.g. "Solenoid" "ICMS" "Solenoid + ICMS")
%           -> Type, ID, N should all be vectors with same number of
%               elements.
%
% Output
%  BinomialSize - Maximum number of responses for "ID" by "Type"
%
% See also: tbl, run_stats.m

T = table(ID,Type,N);

[G,TID] = findgroups(T(:,'ID'));

TID.BinomialSize = splitapply(@(x)max(x),T.N,G);

[T,iOrig] = outerjoin(T,TID,...
   'Keys',{'ID'},...
   'Type','left',...
   'LeftVariables',{'ID','Type','N'},...
   'RightVariables',{'BinomialSize'});

[~,iSort] = sort(iOrig,'ascend');
T = T(iSort,:);

BinomialSize = T.BinomialSize;

end