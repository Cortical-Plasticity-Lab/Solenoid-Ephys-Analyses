function T = reduceData(T,varargin)
%REDUCEDATA Return reduced table version
%
%  T = utils.reduceData(T);
%  T = utils.reduceData(T,'Name',value,...);
%     
%
% Inputs
%  T           - Main data table
%  varargin    - 'Name',value parameter pairs
%                 * 'Solenoid_Onset'               : 0.050 (sec)
%                 * 'Solenoid_Offset'              : 0.100 (sec)
%                 * 'ICMS_Onset'                   : 0.000 (sec)
%                 * 'ICMS_Suppression_Bandwidth'   : nan (sec)
%
% Output
%  T           - Same as input but with "bad" rows removed and ICMS
%                 artifact "suppressed" in `responseVar`
%
% See also: Contents

pars = struct;
pars.Solenoid_Onset = 0.05; % Seconds
pars.Solenoid_Offset = 0.10; % Seconds
pars.ICMS_Onset = 0.00; % Seconds
pars.ICMS_Suppression_Bandwidth = nan; % Seconds

fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(varargin{iV},fn);
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

T(isundefined(T.Type),:) = [];
T(T.Type=="ICMS" & T.ICMS_Onset~=pars.ICMS_Onset,:) = [];
T(T.Type=="Solenoid" & T.Solenoid_Onset~=pars.Solenoid_Onset & T.Solenoid_Offset~=pars.Solenoid_Offset,:) = [];
T(T.Type=="Solenoid + ICMS" & T.Solenoid_Onset~=pars.Solenoid_Onset & T.Solenoid_Offset~=pars.Solenoid_Offset & T.ICMS_Onset~=pars.ICMS_Onset,:) = [];

end