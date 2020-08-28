function params = parseTitle(params,filtArgs)
%PARSETITLE Parses title from filter input arguments
%
%  params = utils.parseTitle(params,filtArgs);
%
% Inputs
%  params   - Parameters struct with 'Title' field
%  filtArgs - Cell array of {'Variable',value,...} pairs for slicing
%
% Output
%  params   - Updates 'Title' field with string of concatenated values
%              based on values from filtArgs that were included in the
%              table.
%
% See also: utils, utils.checkXYLabels, tbl.gfx, tbl.gfx.PETH, tbl.gfx.PEP

if (nargin < 2) || isempty(filtArgs)
   return;
end

str = cell(numel(filtArgs)/2,1);
idx = 0;
for iG = 2:2:numel(filtArgs)
   idx = idx + 1;
   if isnumeric(filtArgs{iG})
      str{idx} = char(strcat(filtArgs{iG-1},': ',string(filtArgs{iG})));
   elseif iscategorical(filtArgs{iG})
      str{idx} = char(strjoin(string(filtArgs{iG}),' & '));
   elseif ischar(filtArgs{iG})
      str{idx} = filtArgs{iG};
   else
      str{idx} = char(strjoin(filtArgs{iG},' & '));
   end
end
if isempty(params.Title)
   params.Title = strjoin(str,'|');
else
   params.Title = [params.Title '||' strjoin(str,'|')];
end

end