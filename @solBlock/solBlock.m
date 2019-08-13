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
      ICMS_Channel_Name
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      folder
      
      sol
      trig
      
      ICMS_Channel_Index
      Layout
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
         obj.setLayout;
         
         in = load(fullfile(obj.folder,[obj.Name id.gen]),'info');
         obj.fs = in.info.frequency_pars.amplifier_sample_rate;
         
         in = load(fullfile(obj.folder,[obj.Name subf.raw],[obj.Name id.info]));
         for iCh = 1:numel(in.RW_info)
            obj.Children = [obj.Children; solChannel(obj,in.RW_info(iCh))];
         end
         
         %% Set default depth
         obj.Depth = cfg.default('depth'); % depth in microns of highest channel
         
         %% Get other metadata
         
         
         obj.sol = fullfile(obj.folder,[obj.Name subf.dig],...
            [obj.Name id.sol]);
         obj.trig = fullfile(obj.folder,[obj.Name subf.dig],...
            [obj.Name id.trig]);
         
         obj.parseStimuliTimes;
         
         
      end
      
      % Set the depth manually (after object creation)
      function setDepth(obj,newDepth)
         obj.Depth = newDepth;
      end
      
      % Set the site layout pattern
      function setLayout(obj,L)
         if nargin < 2
            L = cfg.default('L');
         end
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).setLayout(L);
            end
            return;
         end
         obj.Layout = L;         
      end
      
      function batchPETH(obj,tPre,tPost,binWidth,subset)
         if nargin < 4
            binWidth = cfg.default('binwidth');
         end
         
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               if nargin < 5
                  batchPETH(obj(ii),tPre,tPost,binWidth);
               else
                  batchPETH(obj(ii),tPre,tPost,binWidth,subset);
               end
            end
            return;
         end
         
         if nargin < 5
            subset = 1:numel(obj.Children);
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
            
            savefig(f,fullfile(outpath,[obj.Name '_' obj.Children(ii).Name id.peth '.fig']));
            saveas(f,fullfile(outpath,[obj.Name '_' obj.Children(ii).Name id.peth '.png']));
            
            delete(f);
            
         end
      end
      
      function probePETH(obj,tPre,tPost,binWidth,batchRun)
         if nargin < 5
            batchRun = false;
         end
         
         if nargin < 4
            binWidth = cfg.default('binwidth');
         end
         
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               probePETH(obj(ii),tPre,tPost,binWidth,batchRun);
            end
            return;
         end
         
         edgeVec = tPre:binWidth:tPost;   
         
         lFig = figure('Name',sprintf('%s - Left Hemisphere PETH',obj.Name),...
            'Units','Normalized',...
            'Position',[0.1 0.1 0.4 0.8],...
            'Color','w');
         
         if isempty(obj.Layout) % If no Layout, use default from config
            obj.setLayout;
         end
           
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Left);
         for ii = 1:numel(c)
            idx = find(contains({c.Name},obj.Layout{ii}),1,'first');
            subplot(round(numel(obj.Layout)/4),4,ii);
            PETH(c(idx),edgeVec,1,false);
         end
         suptitle('Left Hemisphere');
         
         rFig = figure('Name',sprintf('%s - Right Hemisphere PETH',obj.Name),...
            'Units','Normalized',...
            'Position',[0.5 0.1 0.4 0.8],...
            'Color','w');
         
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Right);
         for ii = 1:numel(c)
            idx = find(contains({c.Name},obj.Layout{ii}),1,'first');
            subplot(round(numel(obj.Layout)/4),4,ii);
            PETH(c(idx),edgeVec,1,false);
         end
         suptitle('Right Hemisphere');
         
         if batchRun
            subf = cfg.default('subf');
            id = cfg.default('id');
            
            outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.probeplots);
            if exist(outpath,'dir')==0
               mkdir(outpath);
            end
            
            savefig(lFig,fullfile(outpath,[obj.Name id.probepeth '-L.fig']));
            savefig(rFig,fullfile(outpath,[obj.Name id.probepeth '-R.fig']));
            saveas(lFig,fullfile(outpath,[obj.Name id.probepeth '-L.png']));
            saveas(rFig,fullfile(outpath,[obj.Name id.probepeth '-R.png']));
            delete(lFig);
            delete(rFig);
         end
         
      end
      
      function fig = PETH(obj,tPre,tPost,binWidth,subset)
         if nargin < 5
            subset = 1:numel(obj.Children);
         else
            subset = reshape(subset,1,numel(subset));
         end
         
         if nargin < 4
            binWidth = cfg.default('binwidth');
         end
         
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         obj.parseStimuliTimes;
         
         edgeVec = tPre:binWidth:tPost;         
         fig = PETH(obj.Children(subset),edgeVec);
         
      end
      
      function probeLFPcoherence(obj,tPre,tPost)
         
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               probeLFPcoherence(obj(ii),tPre,tPost);
            end
            return;
         end
         
         subf = cfg.default('subf');
         id = cfg.default('id');
         
%          outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.probeplots,subf.lfpcoh);
         outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.probeplots);
         if exist(outpath,'dir')==0
            mkdir(outpath);
         end
         
         
         if isempty(obj.Triggers)
            fprintf(1,'Trigger times not yet parsed for %s.\n',obj.Name,obj.Name);
            return;
         end
         
         
         if isempty(obj.Layout) % If no Layout, use default from config
            obj.setLayout;
         end
         
         tpre = tPre * 1e3;
         tpost = tPost * 1e3;
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Left);
         fs = c(1).fs_d;
         t = tPre:(1/fs):tPost;
         t = t(1:(end-1)) + mode(diff(t)/2);
         x = zeros(size(t));
         for ii = 1:numel(c)
            X = c(ii);
            x = x + mean(getAlignedLFP(X),1); 
%             t = linspace(tpre,tpost,numel(x));
%             fig = figure('Name',sprintf('%s - %s Left Hemisphere Coherence',obj.Name,X.Name),...
%                'Units','Normalized',...
%                'Position',[0.1 0.1 0.4 0.8],...
%                'Color','w');
%             for ik = 1:numel(c)
%                y = mean(getAlignedLFP(c(ik)),1);
%                idx = find(contains({c.Name},obj.Layout{ik}),1,'first');
%                subplot(round(numel(obj.Layout)/4),4,ik);
%                wcoherence(x,y,X.fs_d,'PhaseDisplayThreshold',0.8);
%                xl = str2double(get(gca,'XTickLabel'));
%                xl = xl + min(t);
%                xl = reshape(xl,numel(xl),1);
%                set(gca,'XTickLabel',cellstr(num2str(xl)));
%             end
%             suptitle('Left Hemisphere');
%             savefig(fig,fullfile(outpath,[obj.Name id.lfpcoh '-' X.Name '-L.fig']));
%             saveas(fig,fullfile(outpath,[obj.Name id.lfpcoh '-' X.Name '-L.png']));
%             delete(fig);
         end
         x = x ./ numel(c);
         
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Right);
         y = zeros(size(t));
         for ii = 1:numel(c)
            Y = c(ii);
            y = y + mean(getAlignedLFP(Y),1); 
            
%             X = c(ii);
%             x = mean(getAlignedLFP(X),1); 
%             t = linspace(tpre,tpost,numel(x));
%             fig = figure('Name',sprintf('%s - %s Right Hemisphere Coherence',obj.Name,X.Name),...
%                'Units','Normalized',...
%                'Position',[0.1 0.1 0.4 0.8],...
%                'Color','w');
%             for ik = 1:numel(c)
%                y = mean(getAlignedLFP(c(ik)),1);
%                idx = find(contains({c.Name},obj.Layout{ik}),1,'first');
%                subplot(round(numel(obj.Layout)/4),4,ik);
%                wcoherence(x,y,X.fs_d,'PhaseDisplayThreshold',0.8);
%                xl = str2double(get(gca,'XTickLabel'));
%                xl = xl + min(t);
%                xl = reshape(xl,numel(xl),1);
%                set(gca,'XTickLabel',cellstr(num2str(xl)));
%             end
%             suptitle('Right Hemisphere');
%             savefig(fig,fullfile(outpath,[obj.Name id.lfpcoh '-' X.Name '-R.fig']));
%             saveas(fig,fullfile(outpath,[obj.Name id.lfpcoh '-' X.Name '-R.png']));
%             delete(fig);
         end
         y = y ./ numel(c);
         
         fig = figure(...
            'Name',sprintf('%s Interhemispheric LFP Coherence',obj.Name),...
            'Units','Normalized',...
            'Position',[0.1 0.1 0.8 0.8],...
            'Color','w');
         
         wcoherence(x,y,fs,'PhaseDisplayThreshold',0.8); %#ok<*PROPLC>
         xl = str2double(get(gca,'XTickLabel'));
         xl = xl + min(t)*1e3;
         set(gca,'XTickLabel',cellstr(num2str(xl)));

         title('Left-Right Hemisphere LFP Coherence',...
            'FontName','Arial','Color','k','FontSize',16);
         savefig(fig,fullfile(outpath,[obj.Name id.lfpcoh '.fig']));
         saveas(fig,fullfile(outpath,[obj.Name id.lfpcoh '.png']));
         delete(fig);

      end
      
      function probeAvgLFPplot(obj,tPre,tPost,batchRun)
         if nargin < 4
            batchRun = false;
         end
         
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               probeAvgLFPplot(obj(ii),tPre,tPost,batchRun);
            end
            return;
         end
         
         edgeVec = [tPre,tPost];   
         
         lFig = figure('Name',sprintf('%s - Left Hemisphere Average LFP',obj.Name),...
            'Units','Normalized',...
            'Position',[0.1 0.1 0.4 0.8],...
            'Color','w');
         
         if isempty(obj.Layout) % If no Layout, use default from config
            obj.setLayout;
         end
           
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Left);
         for ii = 1:numel(c)
            idx = find(contains({c.Name},obj.Layout{ii}),1,'first');
            subplot(round(numel(obj.Layout)/4),4,ii);
            avgLFPplot(c(idx),edgeVec,1,false);
         end
         suptitle('Left Hemisphere');
         
         rFig = figure('Name',sprintf('%s - Right Hemisphere Average LFP',obj.Name),...
            'Units','Normalized',...
            'Position',[0.5 0.1 0.4 0.8],...
            'Color','w');
         
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Right);
         for ii = 1:numel(c)
            idx = find(contains({c.Name},obj.Layout{ii}),1,'first');
            subplot(round(numel(obj.Layout)/4),4,ii);
            avgLFPplot(c(idx),edgeVec,1,false);
         end
         suptitle('Right Hemisphere');
         
         if batchRun
            subf = cfg.default('subf');
            id = cfg.default('id');
            
            outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.probeplots);
            if exist(outpath,'dir')==0
               mkdir(outpath);
            end
            
            savefig(lFig,fullfile(outpath,[obj.Name id.probeavglfp '-L.fig']));
            savefig(rFig,fullfile(outpath,[obj.Name id.probeavglfp '-R.fig']));
            saveas(lFig,fullfile(outpath,[obj.Name id.probeavglfp '-L.png']));
            saveas(rFig,fullfile(outpath,[obj.Name id.probeavglfp '-R.png']));
            delete(lFig);
            delete(rFig);
         end
         
      end
      
      function probeAvgIFRplot(obj,tPre,tPost,batchRun)
         if nargin < 4
            batchRun = false;
         end
         
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               probeAvgIFRplot(obj(ii),tPre,tPost,batchRun);
            end
            return;
         end
         
         edgeVec = [tPre,tPost];   
         
         lFig = figure('Name',sprintf('%s - Left Hemisphere Average IFR',obj.Name),...
            'Units','Normalized',...
            'Position',[0.1 0.1 0.4 0.8],...
            'Color','w');
         
         if isempty(obj.Layout) % If no Layout, use default from config
            obj.setLayout;
         end
           
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Left);
         for ii = 1:numel(c)
            idx = find(contains({c.Name},obj.Layout{ii}),1,'first');
            subplot(round(numel(obj.Layout)/4),4,ii);
            avgIFRplot(c(idx),edgeVec,1,false);
         end
         suptitle('Left Hemisphere');
         
         rFig = figure('Name',sprintf('%s - Right Hemisphere Average IFR',obj.Name),...
            'Units','Normalized',...
            'Position',[0.5 0.1 0.4 0.8],...
            'Color','w');
         
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Right);
         for ii = 1:numel(c)
            idx = find(contains({c.Name},obj.Layout{ii}),1,'first');
            subplot(round(numel(obj.Layout)/4),4,ii);
            avgIFRplot(c(idx),edgeVec,1,false);
         end
         suptitle('Right Hemisphere');
         
         if batchRun
            subf = cfg.default('subf');
            id = cfg.default('id');
            
            outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.probeplots);
            if exist(outpath,'dir')==0
               mkdir(outpath);
            end
            
            savefig(lFig,fullfile(outpath,[obj.Name id.probeavgifr '-L.fig']));
            savefig(rFig,fullfile(outpath,[obj.Name id.probeavgifr '-R.fig']));
            saveas(lFig,fullfile(outpath,[obj.Name id.probeavgifr '-L.png']));
            saveas(rFig,fullfile(outpath,[obj.Name id.probeavgifr '-R.png']));
            delete(lFig);
            delete(rFig);
         end

      end
      
      function fig = avgLFPplot(obj,tPre,tPost,subset)
         if nargin < 4
            subset = 1:numel(obj.Children);
         else
            subset = reshape(subset,1,numel(subset));
         end
         
         if nargin < 3
            tPost = cfg.default('tpost');
         end
         
         if nargin < 2
            tPre = cfg.default('tpre');
         end
         
         obj.parseStimuliTimes;
         
         edgeVec = [tPre,tPost];        
         fig = avgLFPplot(obj.Children(subset),edgeVec);
         
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
      
      function parseStimuliTimes(obj,forceParse)
         if nargin < 2
            forceParse = false;
         end
         
         % Parse array input
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).parseStimuliTimes(forceParse);
            end
            return;
         end
         
         % Get triggers
         if isempty(obj.Triggers) || forceParse
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
         [tStim,obj.ICMS_Channel_Index] = getStims(obj.Children);
         if isnan(obj.ICMS_Channel_Index)
            obj.ICMS_Channel_Name = 'none';
         else
            obj.ICMS_Channel_Name = {obj.Children(obj.ICMS_Channel_Index).Name};
         end
         
         if isempty(tStim)
            obj.ICMS_Onset_Latency = nan;
         else
            nTrain = round(size(tStim,2)/numel(tTrig));
            obj.ICMS_Onset_Latency = nan(nTrain,size(tStim,1));
            for ii = 1:nTrain
               for ik = 1:size(tStim,1)
                  obj.ICMS_Onset_Latency(ii,ik) = tStim(ik,ii) - tTrig(1);
               end
            end
         end
      end
   end
   
   
end