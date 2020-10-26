function optSaveFig(fig,outPath,outName,tag)
%OPTSAVEFIG Optional figure-saving function
%
%  io.optSaveFig(fig,outPath,outName,tag);
%  -> io.optSaveFig(fig,'figures/path','file1');
%
% Inputs
%  fig         - Figure handle
%  outPath     - File path save location or full filename (char array)
%  outName     - Name of output file (no path/extension; char array)
%  varargin    - Optional 'Name',value input arguments
%
% Output
%  - none -
%
% See also: Contents



if nargin < 2
   outPath = pwd;
   outName = sprintf('Untitled_%s',...
      char(datetime('now','Format','yyyy-MM-d_HHmmss')));
end

if nargin < 3
   [outPath,outName,~] = fileparts(outPath);
end

if nargin < 4
   tag = '';
end


if exist(outPath,'dir')==0
   mkdir(outPath);
end

strOpts = [...
   string(outName), ...
   string(sprintf('%s_%%s',outName))...
   ];
tagStr = io.appendTag(tag,strOpts);

fname = fullfile(outPath,tagStr);
saveas(fig,strcat(fname,".png"));
savefig(fig,strcat(fname,".fig"));
delete(fig);

end