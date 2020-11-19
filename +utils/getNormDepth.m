function d = getNormDepth(Depth,Area,Lamina)
%GETNORMDEPTH Return "normalized" depth based on laminar groupings
%
%  d = utils.getNormDepth(Depth,Area,Lamina);
%
% Inputs
%  Depth  - Depth (microns)
%  Area   - Area ("RFA" or "S1", same number of elements as `Depth`)
%  Lamina - Lamina ("Layer II/III" | "Layer IV" | "Layer V" | "Layer VI")
%              -> Same number of elements as Depth & Area
%
% Output
%  d      - "Normalized" Depth which is assumed to follow some random
%              distribution so that values should "clump" according to the
%              within-Lamina approximate normal distribution indicating
%              "confidence" in laminar boundary assignments. 
%
% See also: utils, run_stats.m

A = [repmat("RFA",4,1); repmat("S1",4,1)];
B = repmat(["Layer II/III";"Layer IV";"Layer V";"Layer VI"],2,1);
Value = repmat([-2; -0.5; 0.5; 2],2,1);
ATTR = table(A,B,Value);
ATTR.Properties.VariableNames = {'Area','Lamina','Value'};

Key = (1:numel(Depth))';
T = table(Key,Area,Lamina,Depth);
[G,TID] = findgroups(T(:,{'Area','Lamina'}));
[TID.Z,TID.Key] = splitapply(@(depth,key)getAreaLaminaZScore(depth,key),...
   T.Depth,T.Key,G);

TID = outerjoin(TID,ATTR,'Type','left','Keys',{'Area','Lamina'},...
   'LeftVariables',{'Area','Lamina','Z','Key'},...
   'RightVariables','Value');

d = nan(size(Depth));
for iT = 1:size(TID,1)
   d(TID.Key{iT}) = TID.Z{iT} + TID.Value(iT);
end

   function [z,key] = getAreaLaminaZScore(depth,key)
      %GETAREALAMINAZSCORE Return normal distribution
      
      z = {zscore(depth)};
      key = {key};
   end

end