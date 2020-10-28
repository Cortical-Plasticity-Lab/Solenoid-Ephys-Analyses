function [W,H,D,f] = meanPETH(C,type)
%MEANPETH Analyze mean PETH factors
%
%  analyze.factors.meanPETH(C);
%  [W,H,D,f] = analyze.factors.meanPETH(C,type);
%
% Inputs
%  C - Channels table type
%  type - Type of trials (string); if not specified, default is "All" (uses
%           all trials). "Solenoid" | "Solenoid + ICMS" | "ICMS"
%
% Output
%  W - Time-weightings cell array 
%  H - Channel-weightings cell array
%  D - Array of root-mean-square error in each factor reconstruction
%  f - Number of factors corresponding to elements of other outputs
%
% See also: Contents, utils, utils.getFactors_Batch, utils.getFactors

if nargin < 2
   type = ["Solenoid", "Solenoid + ICMS", "ICMS"];
end
if numel(type) == 1
   tag = sprintf('_%s',type);
else
   tag = '_All';
end
iC = ismember(string(C.Type),type);
[W,H,D,f] = utils.getFactors_Batch(C(iC,:),'N_Factors',3:20); % May not reproduce results identically each time
tbl.gfx.makeNNMFreconstructionStem(C(iC,:),D,f,tag,[3,6,12]);

t = C.Properties.UserData.t.Spikes;
tbl.gfx.plotNNMFfactors(t,W{1},tag);
tbl.gfx.plotNNMFfactors(t,W{3},tag);
tbl.gfx.plotNNMFfactors(t,W{6},tag);
tbl.gfx.plotNNMFfactors(t,W{12},tag);
tbl.gfx.plotNNMFfactors(t,W{end},tag);

end