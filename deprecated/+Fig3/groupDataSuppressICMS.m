function T = groupDataSuppressICMS(T,responseVar,varargin)
%GROUPDATASUPPRESSICMS Return aggregated data with ICMS "spike" suppressed
%
%  T = Fig3.groupDataSuppressICMS(T);
%  T = Fig3.groupDataSuppressICMS(T,responseVar);
%  T = Fig3.groupDataSuppressICMS(T,responseVar,'Name',value,...);
%     
%
% Inputs
%  T           - Main data table
%  responseVar - Response variable (def: 'LFP')
%  varargin    - 'Name',value parameter pairs
%
% Output
%  T           - Same as input but with "bad" rows removed and ICMS
%                 artifact "suppressed" in `responseVar`
%
% See also: Contents

if nargin < 2
   responseVar = 'LFP';
end

pars = struct;
pars.HPF_Fc = 2.5; % Hz
pars.Solenoid_Onset = 0.05; % Seconds
pars.Solenoid_Offset = 0.10; % Seconds
pars.ICMS_Onset = 0.00; % Seconds
pars.ICMS_Suppression_Bandwidth = 0.015; % Seconds

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

t = T.Properties.UserData.t.(responseVar).*1e-3;
fs = 1/mean(diff(t));

% if ~isnan(pars.ICMS_Suppression_Bandwidth)
%    idx = abs(t - pars.ICMS_Onset) <= pars.ICMS_Suppression_Bandwidth;
%    T(T.Type=="ICMS" | T.Type=="Solenoid + ICMS",:).(responseVar)(:,idx) = 0; % Suppress
% end
% T.LFP = utils.HPF(T.LFP,pars.HPF_Fc,fs);

[~,iICMS] = min(abs(t-pars.ICMS_Onset));
figure; 
plot(t(iICMS:end),T.LFP(randsample(size(T,1),5),iICMS:end));

T.LFP(:,iICMS:end) = utils.HPF(T.LFP(:,iICMS:end),pars.HPF_Fc,fs,T.LFP(:,iICMS));

end