function [ica_mdl,z] = getICs(Y,coeff)
%GETICS Return reconstruction independent components model (rICA) and scores
%
%  [ica_mdl,z] = analyze.factors.getICs(Y,coeff);
%
% Inputs
%  Y     - Data vector for rICA. Rows are observations, columns variables
%  coeff - "Seeding" coefficients
%
% Output
%  ica_mdl - Reconstruction ICA model
%  z       - Independent component scores.
%
% See also: Contents

if nargin < 2
   ica_mdl = rica(Y,3);
else
   ica_mdl = rica(Y,3,'InitialTransformWeights',coeff(:,1:3));
end
z = transform(ica_mdl,Y);

end