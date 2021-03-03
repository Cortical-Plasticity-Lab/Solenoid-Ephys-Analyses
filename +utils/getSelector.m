function C = getSelector(varargin)
%GETSELECTOR Return formatted array for `getConditionPCs` or other selector
%
%  C = utils.getSelector("VariableName1",Value1,'VariableName2',Value2,...)
%
%  Example 1
%  C = utils.getSelector(["Type","Area"],["Solenoid","RFA"]);
%  -> Selector only takes Solenoid trials from RFA
%
%  Example 2
%  C = utils.getSelector("Type","Solenoid","Type","Solenoid + ICMS");
%  -> Selector takes Solenoid or Solenoid + ICMS trials from either area.
%
% Inputs
%  varargin - <'Variable',Value> keyword argument pairs. If a given
%              argument is an array, both elements of pair must have same
%              number of elements.
%
% Output
%  C - Struct array with fields 'Variable' and 'Value', which serves as
%        table selector for functions like tbl.getConditionPCs
%
% See also: Contents, tbl.getConditionPCs

N = numel(varargin);
if rem(N,2)~=0
   error('Must have an even number (pairs) of input arguments!');
end
n = N/2;
C = struct(...
   'Variable',cell(n,1),...
   'Value',cell(n,1) ...
   );
iC = 0;
for iV = 1:2:N
   iC = iC + 1;
   C(iC).Variable = string(varargin{iV});
   if ischar(varargin{iV+1}) || iscategorical(varargin{iV+1})
      C(iC).Value = string(varargin{iV+1});
   else
      C(iC).Value = varargin{iV+1};
   end
   if numel(C(iC).Variable) ~= numel(C(iC).Value)
      error([...
         '<strong>Number of elements in selector (`C`) element %d does not match.</strong>\n' ...
         '->\t(%d in `Variable` but %d in `Value` field)'],...
         iC,numel(C(iC).Variable),numel(C(iC).Value));
   end
end

end