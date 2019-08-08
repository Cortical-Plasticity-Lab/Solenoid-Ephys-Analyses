function [path,flag] = getPathTo(promptString)
%% GETPATHTO   Return output from uigetdir basically
%
%  [path,flag] = utils.GETPATHTO;
%  [path,flag] = utils.GETPATHTO(promptString);
%
%  --------
%   INPUTS
%  --------
%  promptString :    Prompt in title of uigetdir dialog box.
%
%  --------
%   OUTPUT
%  --------
%    path      :     Full folder path selected
%
%    flag      :     Returns false if cancel was clicked on uigetdir.
%
% By: Max Murphy  v1.0  2019-08-06  Original version (R2017a)

%%
if nargin < 1
   promptString = 'Select path';
end

%%
path = uigetdir(cfg.default('path'),promptString);

if path == 0
   flag = false;
   fprintf(1,'\nNo path selected.\n');
else
   flag = true;
end

end