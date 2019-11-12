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
      Layout      % Probe layout for this rat
   end

   % Private "under-the-hood" properties
   properties (GetAccess = private, SetAccess = private)
      fbrowser % figBrowser class object handle
   end
   
%% METHODS
   % Class constructor and data-handling methods
   methods (Access = public)
      % SOLRAT class constructor
      function obj = solRat(folder)
         % Get folder location
         if nargin < 1 % If no input
            clc;
            [obj.folder,flag] = utils.getPathTo('Select RAT folder');
            if ~flag
               obj = [];
               return;
            end
         elseif ischar(folder) % "Standard" input
            obj.folder = folder;
         elseif iscell(folder) % Can take cell array of folders
            nRat = numel(folder);
            obj = solRat(nRat);
            for ii = 1:nRat
               obj(ii) = solRat(folder{ii});
            end
            return;
         elseif isnumeric(folder) && isscalar(folder) % Initialize array
            nRat = folder;
            obj = repmat(obj,nRat,1);
            return;
         end
         
         % Get name of rat
         obj.Name = obj.parseName;
         
         % Initialize blocks
         obj.Children = obj.initChildBlocks;
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
      
      % OVERLOADED METHOD: save(obj);
      % Saves in current folder as [obj.Name '.mat'], with obj named as
      % variable 'r'
      function save(obj)
         % Handle object arrays
         if numel(obj) > 1
            for i = 1:numel(obj)
               save(obj(i));
            end
            return;
         end
         
         savetic = tic; % Start timing save
         
         % Notify command window of which SOLRAT is being saved
         fname = fullfile(pwd,[obj.Name '.mat']);
         fprintf(1,...
            'Saving %s (as %s.mat): in progress...\n',...
            obj.Name,obj.Name);

         % Save object as variable 'r' for consistency elsewhere
         r = obj;
         save(fname,'r','-v7.3');
         
         % Update command window
         backspace_str = repmat('\b',1,15);
         savetoc = round(toc(savetic));
         fprintf(1,...
            [backspace_str 'successful!\n-->\t(%g sec elapsed)\n\n'],...
            savetoc);
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
      
      % Set figure browser object
      function setFB(obj,figBrowserObj)
         if numel(obj) > 1
            for i = 1:numel(obj)
               obj(i).setFB(figBrowserObj);
            end
            return;
         end
         
         if ~isa(figBrowserObj,'figBrowser')
            error('figBrowserObj must be of class FIGBROWSER');
         end
         obj.fbrowser = figBrowserObj;
         
      end
   end
   
   % "Graphics" methods (can take SOLRAT array inputs)
   methods (Access = public)
      % Batch export (save and close) PERI-EVENT TIME HISTOGRAMS (PETH) for
      % viewing spike counts in alignment to trials or stimuli, where each
      % figure contains the PETH for a single channel.
      function batchPETH(obj,trialType,tPre,tPost,binWidth)
         if nargin < 5
            binWidth = cfg.default('binwidth');
         end
         
         if nargin < 4
            tPost = cfg.default('tpost');
         end
         
         if nargin < 3
            tPre = cfg.default('tpre');
         end
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               batchPETH(obj(i),trialType,tPre,tPost,binWidth);
            end
            return;
         end
         
         batchPETH(obj.Children,trialType,tPre,tPost,binWidth);
      end
      
      % Batch export (save and close) PERI-EVENT TIME HISTOGRAMS (PETH) for
      % viewing spike counts in alignment to trials or stimuli, where each
      % figure contains subplots organized by probe LAYOUT for all channels
      % in a given recording BLOCK
      function batchProbePETH(obj,trialType,tPre,tPost,binWidth)
         if nargin < 5
            binWidth = cfg.default('binwidth');
         end
         
         if nargin < 4
            tPost = cfg.default('tpost');
         end
         
         if nargin < 3
            tPre = cfg.default('tpre');
         end
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               batchProbePETH(obj(i),trialType,tPre,tPost,binWidth);
            end
            return;
         end
         
         probePETH(obj.Children,trialType,tPre,tPost,binWidth,true);
      end
      
      % Batch export (save and close) TRIAL- or STIMULUS-aligned LFP
      % average plots
      function batchProbeAvgLFPplot(obj,trialType,tPre,tPost)
         if nargin < 4
            tPost = cfg.default('tpost');
         end
         
         if nargin < 3
            tPre = cfg.default('tpre');
         end
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               batchProbeAvgLFPplot(obj(i),trialType,tPre,tPost);
            end
            return;
         end
         
         probeAvgLFPplot(obj.Children,trialType,tPre,tPost,true);
      end
      
      % Batch export (save and close) TRIAL- or STIMULUS-aligned
      % INSTANTANEOUS FIRING RATE (IFR; spike rate estimate) average plots
      function batchProbeAvgIFRplot(obj,trialType,tPre,tPost)
         if nargin < 4
            tPost = cfg.default('tpost');
         end
         
         if nargin < 3
            tPre = cfg.default('tpre');
         end
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               batchProbeAvgIFRplot(obj(i),trialType,tPre,tPost);
            end
            return;
         end
         
         probeAvgIFRplot(obj.Children,trialType,tPre,tPost,true);
      end
      
      % Batch export (save and close) TRIAL- or STIMULUS-aligned COHERENCE
      % plots for LFP-LFP cross-channel COHERENCE.
      function batchLFPcoherence(obj,trialType,tPre,tPost)
         if nargin < 4
            tPost = cfg.default('tpost');
         end
         
         if nargin < 3
            tPre = cfg.default('tpre');
         end
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               batchLFPcoherence(obj(i),trialType,tPre,tPost);
            end
            return;
         end
         
         probeLFPcoherence(obj.Children,trialType,tPre,tPost);
      end
      
      % OVERLOADED METHOD for OPENFIG - lets you view rat object figures
      % more easily.
      function openfig(obj)
         if isempty(obj(1).fbrowser)
            obj(1).fbrowser = figBrowser(obj);
         else
            open(obj(1).fbrowser);
         end
      end
         
   end
   
   % Private "helper" methods (for initialization, etc.)
   methods (Access = private)
      % Initialize CHILDREN (SOLBLOCK class objects), each of which is a
      % separate recording (experiment) for this SOLRAT object
      function Children = initChildBlocks(obj)
         F = dir(fullfile(obj.folder,[obj.Name '*']));
         Children = solBlock(numel(F)); % Initialize array
         for iF = 1:numel(F)
            Children(iF) = solBlock(obj,fullfile(F(iF).folder,F(iF).name));
         end
      end
      
      % Parse RAT name from folder (path) hierarchical structure
      function Name = parseName(obj)
         name = strsplit(obj.folder,filesep);
         Name = name{end};
      end
   end
   
   % Static "helper" method for retrieving defaults
   methods (Static = true)
      % Wrapper function to get variable number of default fields 
      % (see cfg.default)
      function varargout = getDefault(varargin)
         % Parse input
         if nargin > nargout
            error('More inputs specified than requested outputs.');
         elseif nargin < nargout
            error('More outputs requested than inputs specified.');
         end
         
         % Collect fields into output cell array
         varargout = cfg.default(varargin);  
      end
   end
   
end