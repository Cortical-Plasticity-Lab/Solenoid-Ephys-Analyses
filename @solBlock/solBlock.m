classdef solBlock < handle
   
   properties (Access = public)
      
      
   end
   
   properties (SetAccess = immutable)
      Name
      Parent
      Children
      Index
      fs
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      Depth
      Triggers
      Solenoid_Onset_Latency
      Solenoid_Offset_Latency
      ICMS_Onset_Latency
      ICMS_Channel
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      folder
      
      sol
      trig
   end
   
   methods (Access = public)
      function obj = solBlock(ratObj,folder)
         %% Set the folder
         if nargin < 1
            [obj.folder,flag] = utils.getPathTo('Select BLOCK folder');
            if ~flag
               obj = [];
               return;
            end
            obj.Parent = [];
         elseif isa(ratObj,'solRat') && nargin > 1
            obj.Parent = ratObj;
            obj.folder = folder;
         else
            obj.folder = ratObj;
            obj.Parent = [];
         end
         
         name = strsplit(obj.folder,filesep);
         obj.Name = name{end};
         tag = strsplit(obj.Name,'_');
         obj.Index = str2double(tag{end});
         
         %% Get all the channels
         subf = cfg.default('subf');
         id = cfg.default('id');
         
         in = load(fullfile(obj.folder,[obj.Name subf.raw],[obj.Name id.info]));
         for iCh = 1:numel(in.RW_info)
            obj.Children = [obj.Children; solChannel(obj,in.RW_info(iCh))];
         end
         
         %% Set default depth
         obj.Depth = cfg.default('depth'); % depth in microns of highest channel
         
         %% Get other metadata
         in = load(fullfile(obj.folder,[obj.Name id.gen]),'info');
         obj.fs = in.info.frequency_pars.amplifier_sample_rate;
         
         obj.sol = fullfile(obj.folder,[obj.Name subf.dig],...
            [obj.Name id.sol]);
         obj.trig = fullfile(obj.folder,[obj.Name subf.dig],...
            [obj.Name id.trig]);
         
      end
      
      % Set the depth manually (after object creation)
      function setDepth(obj,newDepth)
         obj.Depth = newDepth;
      end
      
      function batchPETH(obj,tPre,tPost,binWidth)
         if nargin < 4
            binWidth = 0.002;
         end
         
         if nargin < 3
            tPost = 0.300;
         end
         
         if nargin < 2
            tPre = -0.150;
         end
         
         edgeVec = tPre:binWidth:tPost;

         subf = cfg.default('subf');
         id = cfg.default('id');
         
         outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.peth);
         if exist(outpath,'dir')==0
            mkdir(outpath);
         end
         
         obj.parseStimuliTimes
         
         for ii = subset

            f = PETH(obj.Children(ii),edgeVec,ii);
            
            savefig(f,fullfile(outpath,[block.Name '_' obj.Children(ii).Name id.peth '.fig']));
            saveas(f,fullfile(outpath,[block.Name '_' obj.Children(ii).Name id.peth '.png']));
            
            delete(f);
            
         end
      end
      
      function fig = PETH(obj,tPre,tPost,binWidth,subset)
         if nargin < 5
            subset = 1:numel(obj.Children);
         else
            subset = reshape(subset,1,numel(subset));
         end
         
         if nargin < 4
            binWidth = 0.002;
         end
         
         if nargin < 3
            tPost = 0.300;
         end
         
         if nargin < 2
            tPre = -0.150;
         end
         
         obj.parseStimuliTimes;
         
         edgeVec = tPre:binWidth:tPost;         
         fig = PETH(obj.Children(subset),edgeVec);
         
      end
      
      function pos = getFigPos(obj,ii)
         pos = cfg.default('figpos');
         scl = cfg.default('figscl');
         pos(1) = pos(1) + scl * (ii/numel(obj.Children));
         pos(2) = pos(2) + scl * (ii/numel(obj.Children));
      end
      
      function ts = getTrigs(obj)
         in = load(obj.trig,'data');
         if sum(in.data) == 0
            ts = [];
            return;
         end
         
         data = find(in.data > 0);
         ts = data([true, diff(data) > 1]) ./ obj.fs;
         obj.Triggers = ts;
      end
      
      function ts = getSolOnset(obj,db)
         in = load(obj.sol,'data');
         if sum(in.data) == 0
            ts = [];
            return;
         end
         
         if nargin < 2
            db = 1;
         end
         
         data = find(in.data > 0);
         ts = data([true, diff(data) > db]) ./ obj.fs;
      end
      
      function ts = getSolOffset(obj,db)
         in = load(obj.sol,'data');
         if sum(in.data) == 0
            ts = [];
            return;
         end
         
         if nargin < 2
            db = 1; % Default of no debounce
         end
         
         data = find(in.data > 0);
         ts = data([diff(data) > db, true]) ./ obj.fs;
      end
      
      function parseStimuliTimes(obj)
         % Get triggers
         if isempty(obj.Triggers)
            obj.getTrigs;
         else
            return; % Otherwise it was already done
         end
         tTrig = obj.Triggers;
         
         % Get solenoid stim duration
         tSolOnset = obj.getSolOnset(obj.fs/4);
         tSolOnsetAll = obj.getSolOnset;
         if isempty(tSolOnsetAll)
            obj.Solenoid_Onset_Latency = nan;
         else
            nTrain = round(numel(tSolOnsetAll)/numel(tSolOnset));
            obj.Solenoid_Onset_Latency = nan(1,nTrain);
            for ii = 1:nTrain
               obj.Solenoid_Onset_Latency(ii) = tSolOnsetAll(ii) - tTrig(1);
            end
         end
         
         tSolOffset = obj.getSolOffset(obj.fs/4);
         tSolOffsetAll = obj.getSolOffset;
         if isempty(tSolOffsetAll)
            obj.Solenoid_Offset_Latency = nan;
         else
            nTrain = round(numel(tSolOffsetAll)/numel(tSolOffset));
            obj.Solenoid_Offset_Latency = nan(1,nTrain);
            for ii = 1:nTrain
               obj.Solenoid_Offset_Latency(ii) = tSolOffsetAll(ii) - tTrig(1);
            end
         end
         
         % Get ICMS info
         [tStim,obj.ICMS_Channel] = getStims(obj.Children);
         if isempty(tStim)
            obj.ICMS_Onset_Latency = nan;
         else
            nTrain = round(numel(tStim)/numel(tTrig));
            obj.ICMS_Onset_Latency = nan(1,nTrain);
            for ii = 1:nTrain
               obj.ICMS_Onset_Latency(ii) = tStim(ii) - tTrig(1);
            end
         end
      end
   end
   
   
end