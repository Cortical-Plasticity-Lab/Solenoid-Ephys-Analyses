function [namedVar,varArgs] = parseNamedVariable(varArgs,namedVar,Name)
%PARSENAMEDVARIABLE Parse optional inputs and update a named variable
%
%  namedVar = utils.parseNamedVariable(varArgs,namedVar);
%  [output,varArgs] = utils.parseNamedVariable(varArgs,output,'Name');
%
%  Example:
%  varargin = {'par1',val1,...,'PARAM',PARAMVAL,...};
%  [varargin,PARAM] = utils.parseNamedVariable(varargin,PARAM);
%     -> Removes 'PARAM' and PARAMVAL from list (note that input variable 
%        name must match the name in the list provided via varargin)
%
%  varargin = {'par1',val1,...,'park',valk,...};
%  [varargin,params.variable] = ...
%     utils.parseNamedVariable(varargin,params.variable,'park');
%     -> Can explicitly state the name to match
%
% Inputs
%  varArgs - Typically from parent function, via varargin; list of
%              'Name',value pairs, given as a cell array
%  namedVar - Either given as the "constant" variable to match, or the name
%              of a variable in the "varargin" list (varArgs) to match.
%  Name  - (Optional) give this to explicitly specify the name from list to
%              match.
%
% Output
%  namedVar - If a match is found, then this value is updated using matched
%                 value from varArgs list.
%  varArgs - If a matched name is found, then the variable and
%              corresponding element are returned from this matched list.
%
% See also: utils, utils.addLegendToAxes

if nargin < 3
   Name = inputname(2);
end

if numel(varArgs) > 1
   idx = strcmpi(varArgs(1:2:end),Name);
   if any(idx)
      idx = find(idx,1,'first');
      idx = 2*(idx-1)+1;
      namedVar = varArgs{idx+1};
      varArgs([idx,idx+1]) = [];
   end
end

end