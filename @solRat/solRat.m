classdef solRat < handle
   
   properties (SetAccess = immutable)
      Name
      Children
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      folder
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      Layout
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
      
      function solBlockObj = Block(obj,Index)
         % Add error parsing for indexing
         if Index > (numel(obj.Children)+1)
            error('Index (%d) is too large for %s.',Index,obj.Name);
         end
         if Index < 0
            error('Index (%d) cannot be negative.',Index);
         end
         if isnan(Index)
            error('Index is NaN. Did something else go wrong?');
         end
         
         idx = find([obj.Children.Index] == Index,1,'first');
         solBlockObj = obj.Children(idx);
      end
      
      function batchPETH(obj,tPre,tPost,binWidth)
         if nargin < 4
            binWidth = cfg.default('binwidth');
         end
         
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         batchPETH(obj.Children,tPre,tPost,binWidth);
      end
      
      function batchProbePETH(obj,tPre,tPost,binWidth)
         if nargin < 4
            binWidth = cfg.default('binwidth');
         end
         
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         probePETH(obj.Children,tPre,tPost,binWidth,true);
      end
      
      function batchProbeAvgLFPplot(obj,tPre,tPost)
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         probeAvgLFPplot(obj.Children,tPre,tPost,true);
      end
      
      function batchProbeAvgIFRplot(obj,tPre,tPost)
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         probeAvgIFRplot(obj.Children,tPre,tPost,true);
      end
      
      function batchLFPcoherence(obj,tPre,tPost)
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         probeLFPcoherence(obj.Children,tPre,tPost);
      end
      
      function parseStimuliTimes(obj)
         % If called at "Rat" level, force parsing for all BLOCK times
         parseStimuliTimes(obj.Children,true);
      end
      
      function setLayout(obj,L)
         if nargin < 2
            L = cfg.default('L');
         end
         obj.Layout = L;
         setLayout(obj.Children,L);
      end
   end
   
end