classdef solBlock < handle
   
   properties (Access = public)
      
           
   end
   
   properties (SetAccess = immutable)
      Name
      Parent
      Children 
      fs
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      Depth
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
         
         tTrig = getTrigs(obj);
         vec = tPre:binWidth:tPost;
         tvec = vec(1:(end-1)) + binWidth/2;
         
         fig = [];
         col = cfg.default('barcols');
         for ii = subset
         
            tSpike = getSpikes(obj.Children(ii));
            binCounts = zeros(size(tvec));
            for iT = 1:numel(tTrig)
               binCounts = binCounts + histcounts(tSpike-tTrig(iT),vec);
            end
            f = figure('Name',sprintf('%s: %s PETH',obj.Name,obj.Children(ii).Name),...
               'Color','w',...
               'Units','Normalized',...
               'Position',obj.getFigPos(ii));
            bar(tvec*1e3,binCounts,1,...
               'FaceColor',col{obj.Children(ii).Hemisphere},...
               'EdgeColor','none');
            title(obj.Children(ii).Name,'FontName','Arial','FontSize',16,'Color','k');
            xlabel('Time (ms)','FontName','Arial','FontSize',14,'Color','k');
            ylabel('Count','FontName','Arial','FontSize',14,'Color','k');            
            fig = [fig; f]; %#ok<*AGROW>
         end
         
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
      end
      
      function ts = getSolOnset(obj)
         in = load(obj.sol,'data');
         if sum(in.data) == 0
            ts = [];
            return;
         end
         
         data = find(in.data > 0);
         ts = data([true, diff(in.data) > 1]) ./ obj.fs;
      end
      
      function ts = getSolOffset(obj)
         in = load(obj.sol,'data');
         if sum(in.data) == 0
            ts = [];
            return;
         end
         
         data = find(in.data > 0);
         ts = data([diff(in.data) > 1, true]) ./ obj.fs;
      end

            
   end

   
end