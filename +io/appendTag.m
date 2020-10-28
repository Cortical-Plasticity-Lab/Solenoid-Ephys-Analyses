function tagStr = appendTag(tag,strOpts,strCases,varargin)
%APPENDTAG Append tag to string using prescribed format that changes with empty string
%
%  tagStr = io.appendTag(tag,strOpts);
%  tagStr = io.appendTag(tag,strOpts,strCases);
%  tagStr = io.appendTag(tag,strOpts,strCases,'Name',value,...);
%
% Inputs
%  tag      - Char array that is to be parsed for naming
%  strOpts  - "Base" string options
%  strCases - Array of function handles corresponding to what causes each 
%              case of `strOpts`. Note that the last option in `strOpts` is
%              the "Otherwise" condition. 
%                 * If only two inputs are given, then this corresponds to 
%                    {@isempty}
%
% Output
%  tagStr   - String that is either `baseStr` + some combination of `tag`
%              and other formatting, or a different string altogether if
%              `tag` is empty.
%
% See also: Contents

if nargin < 3
   strCases = {@isempty};
end

flag = true;
idx = 0;
while flag && (idx < numel(strCases))
   idx = idx + 1;
   if feval(strCases{idx},tag)
      flag = false;
   end
end

if flag
   if numel(strOpts) <= numel(strCases)
      tagStr = '';
   else
      tagStr = sprintf(strOpts(end),tag);
   end
else
   tagStr = sprintf(strOpts(idx),tag);
end

tagStr = strrep(tagStr,'_','');

end