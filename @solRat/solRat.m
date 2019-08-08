classdef solRat < handle
   
   properties (SetAccess = immutable)
      Name
      Children
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      folder
   end
   
   methods
      function obj = solRat(folder)
         %% Get folder location
         if nargin < 1
            [obj.folder,flag] = utils.getPathTo('Select RAT folder');
            if ~flag
               obj = [];
               return;
            end
         else
            obj.folder = folder;
         end
         
         %% Get name of rat
         name = strsplit(obj.folder,filesep);
         obj.Name = name{end};
         
         %% Initialize blocks
         
         F = dir(fullfile(obj.folder,[obj.Name '*']));
         for iF = 1:numel(F)
            obj.Children = [obj.Children; ...
               solBlock(obj,fullfile(F(iF).folder,F(iF).name))];
         end
      end
   end
   
end