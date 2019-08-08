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
      spikes
      stim
   end
   
   methods
      function obj = solChannel(block,info)
         obj.Parent = block;
         obj.Hemisphere = cfg.Hem(info.port_number);
         obj.Depth = rem(info.custom_order,cfg.default('nshank')) * ...
            cfg.default('spacing') + cfg.default('offset');
         obj.Impedance = info.electrode_impedance_magnitude / 1000;
         obj.Name = info.custom_channel_name;
         
         subf = cfg.default('subf');
         id = cfg.default('id');
         
         obj.raw = fullfile(block.folder,[block.Name subf.raw],...
            sprintf('%s_%s%g_Ch_%03g.mat',block.Name,id.raw,info.port_number,...
            info.native_order));
         obj.filt = fullfile(block.folder,[block.Name subf.filt],...
            sprintf('%s_%s%g_Ch_%03g.mat',block.Name,id.filt,info.port_number,...
            info.native_order));
         obj.spikes = fullfile(block.folder,[block.Name subf.spikes],...
            sprintf('%s_%s%g_Ch_%03g.mat',block.Name,id.spikes,info.port_number,...
            info.native_order));
         obj.stim = fullfile(block.folder,[block.Name subf.dig],subf.stim,...
            sprintf('%s_%s%g_Ch_%03g.mat',block.Name,id.stim,info.port_number,...
            info.native_order));
      end
      
      function data = getRaw(obj,ch,vec)
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
         if ~isinf(vec)
            data = in.data(vec);
         else
            data = in.data;
         end
      end
      
      function data = getFilt(obj,ch,vec)
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
         if ~isinf(vec)
            data = in.data(vec);
         else
            data = in.data;
         end
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
      
      function [ts,stimCh] = getStims(obj)
         
         for ii = 1:numel(obj)
            in = load(obj(ii).stim,'data');
            if sum(in.data) > 0
               data = find(in.data > 0);
               ts = data([true, diff(data)>1]);
               in = load(obj(ii).stim,'fs');
               ts = ts ./ in.fs;
               stimCh = ii;
               return;
            end
         end
         
         ts = [];
         stimCh = nan;
      end
      
      function fig = PETH(obj,edges,ii)
         if nargin < 3
            ii = 1;
         end
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; PETH(obj(ii),edges,ii)];
            end
            return;
         end
         
         if isempty(obj.Parent.Triggers)
            fig = [];
            fprintf(1,'Trigger times not yet parsed for %s (%s).\n',obj.Parent.Name,obj.Name);
            return;
         end
         
         tvec = edges(1:(end-1))+(mode(diff(edges))/2);
         tSpike = getSpikes(obj);
         binCounts = zeros(size(tvec));
         col = cfg.default('barcols');
         
         for iT = 1:numel(obj.Parent.Triggers)
            binCounts = binCounts + histcounts(tSpike-obj.Parent.Triggers(iT),edges);
         end
         
         fig = figure('Name',sprintf('%s: %s PETH',obj.Parent.Name,obj.Name),...
            'Color','w',...
            'Units','Normalized',...
            'Position',obj.Parent.getFigPos(ii));
         bar(tvec*1e3,binCounts,1,...
            'FaceColor',col{obj.Hemisphere},...
            'EdgeColor','none');
         hold on;
         y = [0 max(binCounts + 10)];
         for ii = 1:numel(obj.Parent.ICMS_Onset_Latency)
            tOnset = ones(1,2) * obj.Parent.ICMS_Onset_Latency(ii) * 1e3;
            line(tOnset,y,'Color','m','LineStyle','--','LineWidth',1.5);
         end
         
         y = [0 max(binCounts + 10) max(binCounts + 10) 0];
         for ii = 1:numel(obj.Parent.Solenoid_Onset_Latency)
            x = [ones(1,2) * obj.Parent.Solenoid_Onset_Latency(ii) * 1e3, ...
                 ones(1,2) * obj.Parent.Solenoid_Offset_Latency(ii) * 1e3];
            
            patch(x,y,[0.25 0.25 0.25],'FaceAlpha',0.3,'EdgeColor','none');
         end
         
         title(obj.Name,'FontName','Arial','FontSize',16,'Color','k');
         xlabel('Time (ms)','FontName','Arial','FontSize',14,'Color','k');
         ylabel('Count','FontName','Arial','FontSize',14,'Color','k');
      end
   end
   
end