function h = addTimeIndicatorToAxes(ax,T,timeVar,params,varargin)
%ADDTIMEINDICATORTOAXES Add graphics indicator for some event to an axes
%
%  h = utils.addTimeIndicatorToAxes(ax,T,timeVar,params,'Name',value,...);
%
% Inputs
%  ax       - Axes handle to add the time event to
%  T        - Main database table (probably after "slicing")
%  timeVar  - Variable name from `T` to use to add timing info object line
%  params   - Parameters struct from cfg.gfx() 
%  varargin - (Optional) 'Name',value input argument pairs that can be
%                 specified by the user.
%
% Output
%  h        - Graphics line object that was created to indicate timing
%
% See also: utils, utils.addStimInfoToAxes, tbl.gfx, tbl.gfx.PETH,
%           tbl.gfx.PEP

idx = strcmpi(T.Properties.VariableNames,timeVar);
if sum(idx)==0
   error('<strong>%s</strong> is not a valid Variable (must be member of table variable names)',timeVar);
elseif sum(idx)==1
   if ~strcmp(T.Properties.VariableNames{idx},timeVar)
      warning('Mismatched capitalization for `timeVar` (<strong>%s</strong> vs <strong>%s</strong> in table); using table variable',...
         timeVar,T.Properties.VariableNames{idx},timeVar);
      timeVar = T.Properties.VariableNames{idx};
   end
else
   idx = strcmp(T.Properties.VariableNames,timeVar);
   if sum(idx)~=1
      error('Ambiguous name for timeVar (%s); check capitalization',timeVar);
   end
end

tt = unique(T.(timeVar));
if strcmpi(T.Properties.VariableUnits{timeVar},'sec')
   tt = tt*1e3; % Convert to milliseconds
end
tt = ones(1,2).*tt;

h = line(ax,tt,ax.YLim,'DisplayName',strrep(timeVar,'_',' '),...
   params.TimeIndicatorLineParams{:},varargin{:});

end