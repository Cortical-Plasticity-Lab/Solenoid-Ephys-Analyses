function keyString = makeKey(n,keyMode,preKey)
%MAKEKEY Utility to make random alphanumeric key-string for naming a "row"
%
%  keyString = utils.makeKey(n);
%  --> Automatically sets `keyMode` to 'random'
%  --> Automatically sets `preKey` to ''
%  --> in random keyMode a number of outputs, n, can be specified.
%      in this case it returns [n x 1] cell array of random hashStrings
%      if n is not included, default value is 1 (still returns cell)
%
%  keyString = utils.makeKey(n,keyMode,preKey);
%  --> `keyMode` can be:
%        * 'random' (doees not care about other values generated)
%        * 'unique' (ensures unique values are created)
%  --> `preKey` is any char vector you want prepended to all generated keys

if nargin < 3
   preKey = '';
end

if nargin < 2
   keyMode = 'random';
end

if nargin < 1
   n = 1;
end

switch lower(keyMode)
   case 'random'
      keyString = GenRandomStrings(n);
   case 'unique'
      keyString = GenUniqueRandomStrings(n);
   otherwise
      error(['TAG__:' mfilename ':UnexpectedString'],...
         ['\n\t->\t<strong>[TAG__.MAKEKEY]:</strong> ' ...
          'Invalid ''keyMode'' value (%s): ' ...
          'should be ''random'' or ''unique''\n'],keyMode);
end

if isempty(preKey)
   return;
end
keyString = prependSignature(keyString,preKey);

end

function keyString = prependSignature(keyString,sig)
%PREPENDSIGNATURE  Prepends the characters in sig to start of hashString
%
%  hashString = prependSignature(hashString,sig);
%
%  sig  -- char array to put on start (e.g. 'BB' for block)
%  hashString  -- cell array of char vectors

if ~ischar(sig)
   error(['nigeLab:' mfilename ':invalidSignature'],...
      '''sig'' input must be a char array');
end

k = numel(sig);
keyString = cellfun(@(x) string([sig x((k+1):end)]),...
   cellstr(keyString),...
   'UniformOutput',true);
end

% Function to use for example to get ANIMAL "ID" from BLOCK "CHILD"
% hash "ID" combinations:
function key = xorcascade(x)
%XORCASCADE  Very simple helper function to get unique hash from "sub-hash"
%
%  hash = xorcascade(x);

if numel(x) == 1
   key = int8(x{1});
   return
end
key = bitxor(int8(x{1}),xorcascade(x(2:end)));
end

% Function that does the random string generation (not really a "proper
% hash" but whatever, this is more for anonymization or unique "ID"
% linking)
function keyString = GenRandomStrings(n,nNum,nAlpha)
%GENRANDOMSTRINGS  Create the random strings for "keys"
%
%  keyString = GenRandomStrings(n);
%  keyString = GenRandomStrings(n,nNum);
%  keyString = GenRandomStrings(n,nNum,nAlpha);
%
%  n        --  Number of returned random strings
%  nNum     --  Number of numeric characters per string
%  nAlpha   --  Number of alphabetical characters per string
%
%  keyString  --  Cell array of random strings

OFFSET_NUM = 48; % double('0') (numeric zero)
OFFSET_ALPHA = 97; % double('a')

if nargin < 2
   nNum = 8;
end
if nargin < 3
   nAlpha = 8;
else
   nAlpha = max(nAlpha,1); % Must have at least 1 alphabetical element
end
nTotal = nNum + nAlpha;
keyNum = randi(10,n,nNum) + OFFSET_NUM - 1;
keyAlpha = randi(26,n,nAlpha) + OFFSET_ALPHA - 1;
% Set the first column to ALWAYS be a letter so that hash always returns
% valid variable or field names for convenience
hashIndex = randperm(nTotal-1)+1;
hash = [keyAlpha(:,1),keyNum,keyAlpha(:,2:nAlpha)];
keyString = string(char(hash(:,[1,hashIndex])));
end

% Function that iterates to validate that unique random strings are made
function keyString = GenUniqueRandomStrings(n,nNum,nAlpha)
%GENUNIQUERANDOMSTRINGS  Create the random strings for UNIQUE "hashes"
%
%  keyString = GenUniqueRandomStrings(n);
%  keyString = GenUniqueRandomStrings(n,nNum);
%  keyString = GenUniqueRandomStrings(n,nNum,nAlpha);
%
%  n        --  Number of returned random strings
%  nNum     --  Number of numeric characters per string (optional)
%  nAlpha   --  Number of alphabetical characters per string (optional)
%
%  keyString  --  Cell array of UNIQUE random strings

if nargin < 2
   nNum = 8;
end
if nargin < 3
   nAlpha = 8;
else
   nAlpha = max(nAlpha,1); % Must have at least 1 alphabetical element
end

keyString = [];
while n > 0
   tmp = [keyString; GenRandomStrings(n,nNum,nAlpha)];
   keyString = unique(tmp);
   n = numel(keyString) - n;
end

end