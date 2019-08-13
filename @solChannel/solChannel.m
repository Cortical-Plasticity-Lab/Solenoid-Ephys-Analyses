classdef solChannel < handle
   
   properties (SetAccess = immutable)
      Name           % String name of channel
      Parent         % Block object (experiment)
      Hemisphere     % Left or Right hemisphere
      Depth          % relative site depth (microns)
      Impedance      % probe impedance (kOhms)
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      raw
      filt
      ds
      rate
      spikes
      stim
      Index
      
      fs_d
      ifr
      
      edges
   end
   
   properties (GetAccess = private, SetAccess = immutable)
      port_number
      native_order
      fs
   end
   
   methods (Access = public)
      function obj = solChannel(block,info)
         obj.Parent = block;
         obj.Hemisphere = cfg.Hem(info.port_number);
         obj.Depth = rem(info.custom_order,cfg.default('nshank')) * ...
            cfg.default('spacing') + cfg.default('offset');
         obj.Impedance = info.electrode_impedance_magnitude / 1000;
         obj.Name = info.custom_channel_name;
         obj.Index = (info.native_order+1) + (info.port_number-1)*numel(obj.Parent.Layout);
         
         subf = cfg.default('subf');
         id = cfg.default('id');
         
         obj.port_number = info.port_number;
         obj.native_order = info.native_order;
         obj.fs = block.fs;
         
         obj.setRaw(subf.raw,id.raw);
         obj.setFilt(subf.filt,id.filt);
         obj.setDS(subf.ds,id.ds);
         obj.setSpikes(subf.spikes,id.spikes);
         obj.setStims(subf.dig,id.stim);
         obj.setRate(subf.rate,id.rate);

      end
      
      function [data,t] = getRaw(obj,ch,vec)
         if nargin < 2
            ch = 1:numel(obj);
         end
         if nargin < 3
            vec = inf;
         end
         
         if numel(obj) > 1
            
            data = [];
            for ii = 1:numel(ch)
               data = [data; getRaw(obj(ch(ii)),ch(ii),vec)]; %#ok<*AGROW>
            end
            return;
         end
         
         in = load(obj.raw,'data');
         if nargout > 1
            t = (0:(numel(in.data)-1))/obj.fs;
         end
         
         if ~isinf(vec)
            data = in.data(vec);
            if nargout > 1
               t = t(vec);
            end
         else
            data = in.data;
         end
      end
      
      function setRaw(obj,f,id)
         if nargin < 3
            ID = cfg.default('id');
            id = ID.raw;
         end
         
         if nargin < 2
            subf = cfg.default('subf');
            f = subf.raw;
         end
         
         obj.raw = fullfile(obj.Parent.folder,[obj.Parent.Name f],...
            sprintf('%s_%s%g_Ch_%03g.mat',obj.Parent.Name,id,...
            obj.port_number,...
            obj.native_order));
      end
      
      function [data,t] = getFilt(obj,ch,vec)
         if nargin < 2
            ch = 1:numel(obj);
         end
         if nargin < 3
            vec = inf;
         end
         if numel(obj) > 1
            
            data = [];
            for ii = 1:numel(ch)
               data = [data; getFilt(obj(ch(ii)),ch(ii),vec)];
            end
            return;
         end
         
         in = load(obj.filt,'data');
         if nargout > 1
            t = (0:(numel(in.data)-1))/obj.fs;
         end
         
         if ~isinf(vec)
            data = in.data(vec);
            if nargout > 1
               t = t(vec);
            end
         else
            data = in.data;
         end
      end
      
      function setFilt(obj,f,id)
         if nargin < 3
            ID = cfg.default('id');
            id = ID.filt;
         end
         
         if nargin < 2
            subf = cfg.default('subf');
            f = subf.filt;
         end
         
         obj.filt = fullfile(obj.Parent.folder,[obj.Parent.Name f],...
            sprintf('%s_%s%g_Ch_%03g.mat',obj.Parent.Name,id,...
            obj.port_number,...
            obj.native_order));
      end
      
      function [data,t] = getLFP(obj,ch,vec)
         if nargin < 2
            ch = 1:numel(obj);
         end
         if nargin < 3
            vec = inf;
         end
         if numel(obj) > 1
            
            data = [];
            for ii = 1:numel(ch)
               data = [data; getLFP(obj(ch(ii)),ch(ii),vec)];
            end
            return;
         end
         
         obj.getfs_d;
         
         if nargout > 1
            t = (0:(numel(in.data)-1))/obj.fs_d;
         end
         
         if ~isinf(vec)
            data = in.data(vec);
            if nargout > 1
               t = t(vec);
            end
         else
            data = in.data;
         end
      end
      
      function getfs_d(obj)
         in = load(obj.ds,'data','fs');
         obj.fs_d = in.fs;
      end
      
      function setDS(obj,f,id)
         if nargin < 3
            ID = cfg.default('id');
            id = ID.ds;
         end
         
         if nargin < 2
            subf = cfg.default('subf');
            f = subf.ds;
         end
         
         obj.ds = fullfile(obj.Parent.folder,[obj.Parent.Name f],...
            sprintf('%s_%s%g_Ch_%03g.mat',obj.Parent.Name,id,...
            obj.port_number,...
            obj.native_order));
      end
      
      function data = getSpikes(obj,ch,type)
         if nargin < 2
            ch = 1:numel(obj);
         end
         if nargin < 3
            type = 'ts';
         end
         if numel(obj) > 1
            
            data = cell(numel(ch),1);
            for ii = 1:numel(ch)
               data{ii} = getSpikes(obj(ch(ii)),ch(ii),type);
            end
            return;
         end
         
         switch type
            case {'ts','times','timestamps','peaks','peak_train'}
               in = load(obj.spikes,'peak_train','pars');
               data = find(in.peak_train) ./ in.pars.FS;
               
            case {'wave','waves','waveform','waveforms','spike','spikes'}
               in = load(obj.spikes,'spikes');
               data = in.spikes;
         end
         
      end
      
      function setSpikes(obj,f,id)
         if nargin < 3
            ID = cfg.default('id');
            id = ID.spikes;
         end
         
         if nargin < 2
            subf = cfg.default('subf');
            f = subf.spikes;
         end
         
         obj.spikes = fullfile(obj.Parent.folder,[obj.Parent.Name f],...
            sprintf('%s_%s%g_Ch_%03g.mat',obj.Parent.Name,id,...
            obj.port_number,...
            obj.native_order));
      end
      
      function [ts,stimCh] = getStims(obj)
         
         stimCh = [];
         ts = [];
         
         for ii = 1:numel(obj)
            in = load(obj(ii).stim,'data');
            if sum(abs(in.data)) > 0
               data = find(abs(in.data) > 0);
               t = data([true, diff(data)>1]);
               in = load(obj(ii).stim,'fs');
               ts = [ts; t ./ in.fs];
               stimCh = [stimCh,ii];
            end
         end
         
         if isempty(stimCh)
            stimCh = nan;
         end
      end
      
      function ts = getTrigs(obj)
         if isempty(obj.Parent.Triggers)
            obj.Parent.ParseStimuliTimes;
         end
         ts = obj.Parent.Triggers;
      end
      
      function setStims(obj,f,id)
         if nargin < 3
            ID = cfg.default('id');
            id = ID.stim;
         end
         
         subf = cfg.default('subf');
         if nargin < 2
            f = subf.dig;
         end
         
         obj.stim = fullfile(obj.Parent.folder,[obj.Parent.Name f],subf.stim,...
            sprintf('%s_%s%g_Ch_%03g.mat',obj.Parent.Name,id,...
            obj.port_number,...
            obj.native_order));
      end
      
      function [data,t] = getIFR(obj,ch,vec)
         if nargin < 2
            ch = 1:numel(obj);
         end
         if nargin < 3
            vec = inf;
         end
         if numel(obj) > 1
            
            data = [];
            for ii = 1:numel(ch)
               data = [data; getIFR(obj(ch(ii)),ch(ii),vec)];
            end
            return;
         end
         
         if exist(obj.rate,'file')==0
            obj.estimateRate;
         end
            
         in = load(obj.rate,'data');
         if nargout > 1
            t = (0:(numel(in.data)-1))/obj.fs_d;
         end
         
         if ~isinf(vec)
            data = in.data(vec);
            if nargout > 1
               t = t(vec);
            end
         else
            data = in.data;
         end
      end
      
      function setRate(obj,f,id)
         if nargin < 3
            ID = cfg.default('id');
            id = ID.rate;
         end
         
         if nargin < 2
            subf = cfg.default('subf');
            f = subf.rate;
         end
         
         if isempty(obj.ifr)
            obj.ifr = cfg.default('rate');
         end
         
         obj.rate = fullfile(obj.Parent.folder,[obj.Parent.Name f],...
            sprintf('%s_%s_%03gms-%s_P%g_Ch_%03g.mat',...
            obj.Parent.Name,...
            id,...
            obj.ifr.w,...
            obj.ifr.kernel,...
            obj.port_number,...
            obj.native_order));
         
         if exist(obj.rate,'file')==0
            obj.estimateRate;
         end
      end
      
      function estimateRate(obj,ch)
         if nargin < 2
            ch = 1:numel(obj);
         end
         
         if numel(obj) > 1
            for ii = 1:numel(ch)
               estimateRate(obj(ch(ii)),ch(ii));
            end
            return;
         end
         
         ts = getSpikes(obj,ch,'ts');
         % Get number of samples in record
         m = matfile(obj.ds);
         n = size(m.data,2);
         if isempty(obj.fs_d)
            obj.fs_d = m.fs;
         end
         clear m;
         
         % Get number of samples for smooth width
         W = round(obj.ifr.w * 1e-3 * obj.fs_d);
         fs = obj.fs_d; %#ok<*PROPLC>
         
         data = zeros(1,n);
         if isempty(ts)
            save(obj.rate,'data','fs','-v7.3');
            return;
         end
         data(round(ts*obj.fs_d)) = 1;
         data = utils.fastsmooth(data,W,obj.ifr.kernel,0);
         
         [pname,~,~] = fileparts(obj.rate);
         if exist(pname,'dir')==0
            mkdir(pname);
         end
         save(obj.rate,'data','fs','-v7.3');
      end
      
      function binCounts = getBinnedSpikes(obj,edges)
         if nargin < 2
            if isempty(obj.edges)
               tpre = cfg.default('tpre');
               tpost = cfg.default('tpost');
               bw = cfg.default('binwidth');
               obj.edges = tpre:bw:tpost;
            end
            edges = obj.edges;
         end
         
         tSpike = getSpikes(obj);
         trigs = obj.getTrigs;
         binCounts = zeros(numel(trigs),numel(edges)-1);
         
         for iT = 1:numel(trigs)
            binCounts(iT,:) = histcounts(tSpike-trigs(iT),edges);
         end
      end
      
      function fig = PETH(obj,edges,ii,makeNewFig)
         if isempty(obj)
            fig = [];
            return;
         end
         
         if nargin < 4
            makeNewFig = true;
         end
         if nargin < 3
            ii = 1;
         end
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; PETH(obj(ii),edges,ii,makeNewFig)];
            end
            return;
         end
         
         if isempty(obj.Parent.Triggers)
            fig = [];
            fprintf(1,'Trigger times not yet parsed for %s (%s).\n',obj.Parent.Name,obj.Name);
            return;
         end
         
         col = cfg.default('barcols');
         obj.edges = edges;
         tvec = edges(1:(end-1))+(mode(diff(edges))/2);
         
         binCounts = sum(obj.getBinnedSpikes,1);         
                  
         if makeNewFig
            fig = figure('Name',sprintf('%s: %s PETH',obj.Parent.Name,obj.Name),...
               'Color','w',...
               'Units','Normalized',...
               'Position',obj.Parent.getFigPos(ii));
         end
         
         b = bar(tvec*1e3,mean(binCounts,1),1,...
            'FaceColor',col{obj.Hemisphere},...
            'EdgeColor','none');
         
%          xlim(cfg.default('xlimit'));
         xlim([obj.edges(1) obj.edges(end)]*1e3);
         ylim(cfg.default('ylimit'));
      
         obj.addStimulusMarkers(gca,b);
         obj.addAxesLabels(gca,'Time (ms)','Count');
      end
      
      function addStimulusMarkers(obj,ax,graphicsObj)
         set(ax,'NextPlot','add');
         y = 0.9 * get(ax,'YLim');
         for ii = 1:size(obj.Parent.ICMS_Onset_Latency,1)
            for ik = 1:size(obj.Parent.ICMS_Onset_Latency,2)
               tOnset = ones(1,2) * obj.Parent.ICMS_Onset_Latency(ii,ik) * 1e3;
               if obj.Parent.ICMS_Channel_Index(ik) == obj.Index
                  line(tOnset,y,'Color','m','LineStyle','-','LineWidth',2);
               else
                  line(tOnset,y,'Color','m','LineStyle','--','LineWidth',1.5);
               end
            end
         end
         
         y = [y(1) y(2) y(2) y(1)];
         for ii = 1:numel(obj.Parent.Solenoid_Onset_Latency)
            x = [ones(1,2) * obj.Parent.Solenoid_Onset_Latency(ii) * 1e3, ...
                 ones(1,2) * obj.Parent.Solenoid_Offset_Latency(ii) * 1e3];
            
            patch(x,y,[0.25 0.25 0.25],'FaceAlpha',0.3,'EdgeColor','none');
         end
         
         if  ismember(obj.Index,obj.Parent.ICMS_Channel_Index)
            set(ax,'Color','y');
            if nargin > 2
               if isa(graphicsObj,'matlab.graphics.chart.primitive.Bar')
                  set(graphicsObj,'FaceColor','k');
               elseif isa(graphicsObj,'matlab.graphics.chart.primitive.Line')
                  set(graphicsObj,'Color','k');
               end
            end

         end
      end
      
      function addAxesLabels(obj,ax,xLabelString,yLabelString)
         ax.Title.String = obj.Name;
         ax.Title.FontName = 'Arial';
         ax.Title.FontSize = 16;
         ax.Title.Color = 'k';
         
         ax.XLabel.String = xLabelString;
         ax.XLabel.FontName = 'Arial';
         ax.XLabel.FontSize = 14;
         ax.XLabel.Color = 'k';

         ax.YLabel.String = yLabelString;
         ax.YLabel.FontName = 'Arial';
         ax.YLabel.FontSize = 14;
         ax.YLabel.Color = 'k';
      end
      
      function [data,t] = getAlignedLFP(obj)
         data = getLFP(obj);
         if isempty(obj.edges)
%             error('%s: edges not yet set using any of the PETH methods.',obj.Name);
            tpre = cfg.default('tpre');
            tpost = cfg.default('tpost');
            binwidth = cfg.default('binwidth');
            obj.edges = tpre:binwidth:tpost;
            edges = tpre:(1/obj.fs_d):tpost; %#ok<*PROP>
         else
            edges = obj.edges(1):(1/obj.fs_d):obj.edges(end);
         end
         
         
         trigs = getTrigs(obj);
         trigs = reshape(round(trigs*obj.fs_d),numel(trigs),1);
         tvec = edges(1:(end-1)) + mode(diff(edges))/2;
         tvec = round(tvec*obj.fs_d);
         
         vec = tvec + trigs;
         n = numel(data);
         
         vec(any(vec < 1,2),:) = [];
         vec(any(vec > n,2),:) = [];
         
         data = data(vec);
         
         if nargout > 1
            t = vec * obj.fs_d;
         end
      end
      
      function fig = avgLFPplot(obj,edges,ii,makeNewFig)
         if isempty(obj)
            fig = [];
            return;
         end
         
         if nargin < 4
            makeNewFig = true;
         end
         if nargin < 3
            ii = 1;
         end
         if nargin < 2
            if isempty(obj.edges)
               error('%s: edges not yet set using any of the PETH methods.',obj.Name);
            else
               edges = [obj.edges(1),obj.edges(end)];
            end
         end
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; avgLFPplot(obj(ii),edges,ii,makeNewFig)];
            end
            return;
         end
         
         
         
         if isempty(obj.Parent.Triggers)
            fig = [];
            fprintf(1,'Trigger times not yet parsed for %s (%s).\n',obj.Parent.Name,obj.Name);
            return;
         end
         
         pars = cfg.default('ds');
         if isempty(obj.fs_d)
            in = load(obj.ds,'fs');
            obj.fs_d = in.fs;
         end
         lfp = obj.getAlignedLFP;
         tvec = edges(1):(1/obj.fs_d):edges(2); % relative sample times
         tvec = tvec(1:(end-1)) + mode(diff(tvec))/2;
         
         if makeNewFig
            fig = figure('Name',sprintf('%s: %s average LFP',obj.Parent.Name,obj.Name),...
               'Color','w',...
               'Units','Normalized',...
               'Position',obj.Parent.getFigPos(ii));
         end
         
         t = tvec * 1e3;
         mu = mean(lfp,1);
         sd = std(lfp,[],1) ./ sqrt(size(mu,1));
         
         p = plot(t,mu,...
            'Color',pars.col{obj.Hemisphere},...
            'LineWidth',pars.lw);
         
         xlim(pars.xlimit);
         ylim(pars.ylimit);
      
         obj.addStimulusMarkers(gca,p);
         obj.addAxesLabels(gca,'Time (ms)','LFP (\muV)');

         errbary = [mu + sd, fliplr(mu - sd)];
         errbarx = [t, fliplr(t)];
         patch(errbarx,errbary,pars.col{obj.Hemisphere},...
            'FaceAlpha',0.3,...
            'EdgeColor','none',...
            'FaceColor',pars.col{obj.Hemisphere});
         
      end
      
      function [data,t,t_trial] = getAlignedIFR(obj)
         data = getIFR(obj);
         trigs = getTrigs(obj);
         trigs = reshape(round(trigs*obj.fs_d),numel(trigs),1);
         t = obj.edges(1:(end-1)) + mode(diff(obj.edges))/2;
         tvec = round(t*obj.fs_d);
         
         vec = tvec + trigs;
         n = numel(data);
         
         vec(any(vec < 1,2),:) = [];
         vec(any(vec > n,2),:) = [];
         
         data = data(vec);
         
         if nargout > 1
            t = t * 1e3; % scale to ms
         end
         
         if nargout > 2
            t_trial = vec * obj.fs_d;
         end
      end
      
      function fig = avgIFRplot(obj,edges,ii,makeNewFig)
         if isempty(obj)
            fig = [];
            return;
         end
         
         if nargin < 4
            makeNewFig = true;
         end
         if nargin < 3
            ii = 1;
         end
         if nargin < 2
            if isempty(obj.edges)
               error('%s: edges not yet set using any of the PETH methods.',obj.Name);
            else
               edges = [obj.edges(1),obj.edges(end)];
            end
         end
         
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; avgIFRplot(obj(ii),edges,ii,makeNewFig)];
            end
            return;
         end
         
         
         
         if isempty(obj.Parent.Triggers)
            fig = [];
            fprintf(1,'Trigger times not yet parsed for %s (%s).\n',obj.Parent.Name,obj.Name);
            return;
         end
         
         if isempty(obj.ifr)
            obj.ifr = cfg.default('rate');
         end
         pars = cfg.default('ifr');
         
         if isempty(obj.fs_d)
            obj.getfs_d;
         end
         tvec = edges(1):(1/obj.fs_d):edges(2); % relative sample times
         [ifr,t] = obj.getAlignedIFR;
         ifr = sqrt(abs(ifr));
         ifr = (ifr - mean(ifr,2)) ./ std(ifr,[],1);
%          tvec = obj.edges(1:(end-1)) + mode(diff(obj.edges))/2;
%          binCounts = obj.getBinnedSpikes;
%          ifr = utils.fastsmooth(binCounts,15,'pg',0,1);
         
         if makeNewFig
            fig = figure('Name',sprintf('%s: %s average LFP',obj.Parent.Name,obj.Name),...
               'Color','w',...
               'Units','Normalized',...
               'Position',obj.Parent.getFigPos(ii));
         end
         
%          t = tvec * 1e3;
         mu = mean(ifr,1);
         sd = std(ifr,[],1) ./ sqrt(size(mu,1));
         
         p = plot(t,mu,...
            'Color',pars.col{obj.Hemisphere},...
            'LineWidth',pars.lw);
         
         xlim(pars.xlimit);
         ylim(pars.ylimit);
      
         obj.addStimulusMarkers(gca,p);
         obj.addAxesLabels(gca,'Time (ms)','IFR');

         errbary = [mu + sd, fliplr(mu - sd)];
         errbarx = [t, fliplr(t)];
         patch(errbarx,errbary,pars.col{obj.Hemisphere},...
            'FaceAlpha',0.3,...
            'EdgeColor','none',...
            'FaceColor',pars.col{obj.Hemisphere});
         
      end
      
      
   end
   
end