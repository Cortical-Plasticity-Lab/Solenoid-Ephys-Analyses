classdef solRat < handle
%% SOLRAT obj = solRat(); or obj = solRat('P:\Path\To\Data\R19-###');
%
%  Handle class to organize data collected for a specific experimental
%  animal (acute surgical preparation)

%% PROPERTIES   
   % Immutable properties defined during class construction
   properties (SetAccess = immutable)
      Name        % Name of this SOLRAT object ('R19-###')
      Children    % Array of SOLBLOCK child objects
   end
   
   % Properties that can be publically accessed, but must be changed using 
   % SOLRAT methods only, and don't show up by default in the property list
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      folder  % (full) file path to RAT folder
   end
   
   % Properties that can be publically accessed, but must be changed using 
   % SOLRAT methods only
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      Layout % Probe layout for this rat
   end

%% METHODS
   % Class constructor and data-handling methods
   methods (Access = public)
      % SOLRAT class constructor
      function obj = solRat(folder)
         % Get folder location
         if nargin < 1
            [obj.folder,flag] = utils.getPathTo('Select RAT folder');
            if ~flag
               obj = [];
               return;
            end
         else
            obj.folder = folder;
         end
         
         % Get name of rat
         obj.parseName;
         
         % Initialize blocks
         obj.initChildBlocks;
      end
      
      % Get BLOCK according to "tagged" INDEX (RYY-###_2019_MM_DD_INDEX)
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
      
      % Get ICMS stimuli times for all BLOCKS (children) of this SOLRAT
      % object
      function parseStimuliTimes(obj)
         % If called at "Rat" level, force parsing for all BLOCK times
         parseStimuliTimes(obj.Children,true);
      end
      
   end
   
   % "Set" methods
   methods (Access = public)
      % Set the probe LAYOUT (channel spatial organization, where rows
      % indicate deeper sites and columns indicate mediolateral or
      % rostro-caudal span), for all BLOCKS (children) of this SOLRAT
      % object
      function setLayout(obj,L)
         if nargin < 2
            L = cfg.default('L');
         end
         obj.Layout = L;
         setLayout(obj.Children,L);
      end
   end
   
   % "Graphics" methods
   methods (Access = public)
      % Batch export (save and close) PERI-EVENT TIME HISTOGRAMS (PETH) for
      % viewing spike counts in alignment to trials or stimuli, where each
      % figure contains the PETH for a single channel.
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
      
      % Batch export (save and close) PERI-EVENT TIME HISTOGRAMS (PETH) for
      % viewing spike counts in alignment to trials or stimuli, where each
      % figure contains subplots organized by probe LAYOUT for all channels
      % in a given recording BLOCK
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
      
      % Batch export (save and close) TRIAL- or STIMULUS-aligned LFP
      % average plots
      function batchProbeAvgLFPplot(obj,tPre,tPost)
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         probeAvgLFPplot(obj.Children,tPre,tPost,true);
      end
      
      % Batch export (save and close) TRIAL- or STIMULUS-aligned
      % INSTANTANEOUS FIRING RATE (IFR; spike rate estimate) average plots
      function batchProbeAvgIFRplot(obj,tPre,tPost)
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         probeAvgIFRplot(obj.Children,tPre,tPost,true);
      end
      
      % Batch export (save and close) TRIAL- or STIMULUS-aligned COHERENCE
      % plots for LFP-LFP cross-channel COHERENCE.
      function batchLFPcoherence(obj,tPre,tPost)
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         probeLFPcoherence(obj.Children,tPre,tPost);
      end
      
   end
   
   % Private "helper" methods (for initialization, etc.)
   methods (Access = private)
      % Initialize CHILDREN (SOLBLOCK class objects), each of which is a
      % separate recording (experiment) for this SOLRAT object
      function initChildBlocks(obj)
         F = dir(fullfile(obj.folder,[obj.Name '*']));
         for iF = 1:numel(F)
            obj.Children = [obj.Children; ...
               solBlock(obj,fullfile(F(iF).folder,F(iF).name))];
         end
      end
      
      % Parse RAT name from folder (path) hierarchical structure
      function parseName(obj)
         name = strsplit(obj.folder,filesep);
         obj.Name = name{end};
      end
   end
   
end