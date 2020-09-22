function h = addSolenoidToAxes(ax,T,params,varargin)
%ADDSOLENOIDTOAXES Add indicator of solenoid strike to axes
%
%  h = utils.addSolenoidToAxes(ax,T,params);
%  h = utils.addSolenoidToAxes(ax,T,params,'Name',value,...);
%
% Inputs
%  ax       - Axes handle
%  T        - Main database table
%  params   - Parameters struct
%  varargin - (Optional) 'Name',value input argument pairs
%
% Output
%  h        - Graphics line object for solenoid onset/offset indicator
%
% See also: utils, utils.addTimeIndicatorToAxes, utils.addStimInfoToAxes

onset = unique(T.Solenoid_Onset);
onset(isinf(onset) | isnan(onset)) = [];
if numel(onset)~=1
   warning('%d solenoid strike onset values included. No graphic added.\n',...
      numel(onset));
   h = [];
   return;
end
if strcmpi(T.Properties.VariableUnits{'Solenoid_Onset'},'sec')
   onset = onset*1e3;
end
if isstruct(T.Properties.UserData)
   if isfield(T.Properties.UserData,'SolenoidDelay')
      physicalDelayTime = T.Properties.UserData.SolenoidDelay;
   else
      warning('Missing SolenoidDelay UserData field for input data table.');
      disp('Assigning value of 4-ms (empirically determined)');
      physicalDelayTime = 4; % ms
   end
else
   warning('Missing SolenoidDelay UserData field for input data table.');
   disp('Assigning value of 4-ms (empirically determined)');
end
onset = onset + physicalDelayTime;

% Get solenoid "offset" (time it begins to retract from target)
offset = unique(T.Solenoid_Offset);
offset(isinf(offset) | isnan(offset)) = [];
if numel(offset)~=1
   warning('%d solenoid strike offset values included. No graphic added.\n',...
      numel(offset));
   h = [];
   return;
end
if strcmpi(T.Properties.VariableUnits{'Solenoid_Offset'},'sec')
   offset = offset*1e3;
end
offset = offset + physicalDelayTime;

yConn = ax.YLim(1)+diff(ax.YLim)*0.75;
h = line(ax,[onset,offset],ones(1,2).*yConn,...
   'Tag','Solenoid-Dwell','DisplayName','Solenoid Dwell Time',...
   'Color',params.Color,...
   params.SolenoidLineParams{:},varargin{:});
h.Annotation.LegendInformation.IconDisplayStyle = 'off';
end