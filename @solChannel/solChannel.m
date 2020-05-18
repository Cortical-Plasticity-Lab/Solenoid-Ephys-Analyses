classdef solChannel < handle
%% SOLCHANNEL  obj = solChannel(block,info);
   
%% PROPERTIES
   % Immutable properties set on object construction
   properties (GetAccess = public, SetAccess = immutable, Hidden = false)
      Name           % String name of electrode recording channel
      Parent         % SOLBLOCK object handle (experiment)
   end
   
   % Properties that are not hidden but can't be changed other than by
   % class methods.
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      Hemisphere     % Left or Right hemisphere
      Depth          % relative electrode site depth (microns)
      Impedance      % electrode impedance (kOhms)
   end
   
   % Hidden properties that can be accessed outside of the class
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      raw    % File: RAW data
      filt   % File: BANDPASS FILTERED (unit band) data
      ds     % File: LFP DOWN-SAMPLED LOWPASS FILTERED data
      rate   % File: SPIKE RATE (INSTANTANEOUS FIRING RATE; IFR) estimate
      spikes % File: SPIKE point-process & snippet data
      stim   % File: ICMS stimulation data
      Index  % Channel index as CHILD of parent SOLBLOCK object
      
      fs_d   % Sample rate after decimation (_d)
      ifr    % Struct with fields for IFR estimation parameters
      
      edges  % Edges for histogram binning
   end
   
   % Immutable properties that don't need to be listed with the other
   % public properties that are set on object construction
   properties (GetAccess = public, SetAccess = immutable, Hidden = true)
      port_number    % PROBE used for this recording
      native_order   % Original channel order on INTAN RHS
      custom_order   % CUSTOM channel order used for acquisition on RHS
      fs             % Original sample frequency during recording
   end
   
%% METHODS
   % Class constructor and data-handling methods
   methods (Access = public)
      % Class constructor for SOLCHANNEL object
      function obj = solChannel(block,info)
         if ~isa(block,'solBlock')
            if isscalar(block) && isnumeric(block)
               obj = repmat(obj,block,1); % Initialize empty array
               return;
            else
               error('Check ''block'' input argument (current class: %s)',...
                  class(block));               
            end            
         end
         
         % Set public immutable properties
         obj.Parent = block;
         obj.Impedance = info.electrode_impedance_magnitude / 1000;
         obj.Name = info.custom_channel_name;
         fprintf(1,repmat('\b',1,5));

         % Set "hidden" properties
         obj.port_number = info.port_number;
         obj.native_order = info.native_order;
         obj.custom_order = info.custom_order;
         obj.fs = block.fs;
         
         % Parse channel's INDEX and LOCATION (Depth, Hemisphere)
         obj.parseChannelIndex;
         obj.parseChannelLocation;
         
         % Get configured defaults
         [subf,id] = solChannel.getDefault('subf','id');

         % Set file associations
         obj.setFileAssociations(subf,id);

      end

      % Do actual RATE ESTIMATION for this channel, using a smoothing
      % kernel to get the INSTANTANEOUS FIRING RATE (IFR; spike rate)
      % estimate. Once computed, save the IFR estimate to the hard disk in
      % the BLOCK folder and associate the filename with this CHANNEL
      % object so it can be easily accessed in the future without costly
      % recomputing.
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
         data(min(max(round(ts*obj.fs_d),1),n)) = 1;
         data = utils.fastsmooth(data,W,obj.ifr.kernel,0);
         
         [pname,~,~] = fileparts(obj.rate);
         if exist(pname,'dir')==0
            mkdir(pname);
         end
         save(obj.rate,'data','fs','-v7.3');
      end
      
   end
   
   % "Get" methods
   methods (Access = public)
      % Return LFP aligned to TRIALS for this channel
      function [data,t] = getAlignedLFP(obj,trialType)
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         data = getLFP(obj);
         edges = obj.getSpikeBinEdges; %#ok<*PROP>
         
         
         trials = getTrials(obj,trialType);
         vec = round(edges(1)*obj.fs_d) : round(edges(end)*obj.fs_d);
         itrials = round(trials * obj.fs_d);
         itrials = reshape(itrials,numel(itrials),1);
         
         t = vec / obj.fs_d * 1e3;
         
         vec = vec + itrials;
         n = numel(data);
         
         vec(any(vec < 1,2),:) = [];
         vec(any(vec > n,2),:) = [];
         
         data = data(vec);
         
      end
      
      % Return INSTANTANEOUS FIRING RATE (IFR; spike rate) aligned to
      % TRIALS for this channel
      function [data,t,t_trial] = getAlignedIFR(obj,trialType)
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         data = getIFR(obj);
         trials = getTrials(obj,trialType);
         trials = reshape(round(trials*obj.fs_d),numel(trials),1);
         t = obj.edges(1:(end-1)) + mode(diff(obj.edges))/2;
         tvec = round(t*obj.fs_d);
         
         vec = tvec + trials;
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
      
      % Returns matrix of counts of binned spikes (histograms) where each
      % row is a TRIAL and each column is a bin. 
      function binCounts = getBinnedSpikes(obj,trialType,tPre,tPost,binWidth)
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if nargin == 5
            obj.setSpikeBinEdges(tPre,tPost,binWidth);
         end
         edges = obj.getSpikeBinEdges;
         
         tSpike = getSpikes(obj);
         trials = obj.getTrials(trialType);
         binCounts = zeros(numel(trials),numel(edges)-1);
         
         for iT = 1:numel(trials)
            binCounts(iT,:) = histcounts(tSpike-trials(iT),edges);
         end
         binCounts = min(binCounts,1); % Clip to 1 spike per bin
      end
      
      % Returns BANDPASS FILTERED (UNIT) data for this channel
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
      
      % Returns DECIMATED SAMPLE RATE (for LFP) for this channel
      function getfs_d(obj)
         in = load(obj.ds,'fs');
         obj.fs_d = in.fs;
      end
      
      % Returns LOWPASS FILTERED (DECIMATED; LFP) data for this channel
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
         in = load(obj.ds,'data');
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
      
      % Returns RAW data for this channel (and corresponding sample times)
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
      
      % Returns SPIKE point process data for this channel
      % Depending on 'type' arg, either returns a vector of peak times
      % (point process), or a data matrix of snippet waveforms
      % with rows corresponding one-to-one with elements of peak times.
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
      
      % Return SPIKE BIN EDGES used to generate spike histograms or rasters
      function edges = getSpikeBinEdges(obj)
         if isempty(obj.edges)
            obj.setSpikeBinEdges;
         end
         edges = obj.edges;
      end
      
      % Return times of ICMS stimuli (as a point process vector of times)
      % Second output argument gives channels that were stimulated
      % Second input argument defaults to false unless specified as true,
      % in which case the ICMS info file is overwritten. If no ICMS info
      % file exists, a new one is created.
      function [ts,stimCh] = getStims(obj,force_overwrite)
         
         if nargin < 2
            force_overwrite = false;
         end
         
         stimCh = [];
         ts = [];
         
         if (~force_overwrite)
            if exist(obj(1).Parent.stim,'file')~=0
               in = load(obj(1).Parent.stim,'ts','stimCh');
               ts = in.ts;
               stimCh = in.stimCh;
               return;
            end            
         end
         
         fprintf(1,'-->\tParsing ICMS channel(s)...');
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
         fprintf(1,'complete\n');
         
         if isempty(stimCh)
            stimCh = nan;
         end
         
         out = struct;
         out.ts = ts;
         out.stimCh = stimCh; %#ok<*STRNU>
         save(obj(1).Parent.stim,'-struct','out');
      end
      
      % Return times of TRIALS as a vector of time stamps. Can specify a
      % subset of trial types using second arg (see cfg.TrialType)
      function ts = getTrials(obj,trialType)
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if trialType >= 100
            ts = obj.Parent.Trials;
         else
            ts = obj.Parent.Trials(ismember(...
               obj.Parent.TrialType,...
               trialType));
         end
      end
      
      % Return times of "triggers" (TRIALS) as a vector of time stamps
      function ts = getTrigs(obj)
         if isempty(obj.Parent.Triggers)
            obj.Parent.ParseStimuliTimes;
         end
         ts = obj.Parent.Triggers;
      end
      
      % Returns the INSTANTEOUS FIRING RATE (IFR; spike rate) estimate for
      % this channel, as well as the corresponding sample times
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
      
      
   end
   
   % "Set" methods
   methods (Access = public)
      % Set the RAW data file for this channel
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
      
      % Set the FILTERED data file for this channel
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
      
      % Set the DOWNSAMPLED LFP data file for this channel
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
      
      % Set the RATE ESTIMATE data file for this channel
      function setRate(obj,f,id,doRateEstimate)
         if nargin < 4
            doRateEstimate = false;
         end
         
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
         
         if (exist(obj.rate,'file')==0) && (doRateEstimate)
            obj.estimateRate;
         end
      end
      
      % Set the SPIKE data file for this channel
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
      
      % Set the BIN EDGES used to generate HISTOGRAMS or AVERAGE IFR plots
      % for this channel
      function setSpikeBinEdges(obj,tPre,tPost,binWidth)
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
               obj(ii).setSpikeBinEdges(tPre,tPost,binWidth);
            end
            return;
         end
         
         obj.edges = tPre:binWidth:tPost;
      end
      
      % Set the STIM data file for this channel
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
      
   end
   
   % "Graphics" methods
   methods (Access = public)
      % Add markers denoting ICMS to a given axes
      function addStimulusMarkers(obj,ax,graphicsObj,pct)
         if nargin < 4
            pct = 0.9;
         end
         
         % Superimpose lines indicating timing of ICMS pulses
         set(ax,'NextPlot','add');
         Y = pct * get(ax,'YLim');
         for ii = 1:size(obj.Parent.ICMS_Onset_Latency,1)
            for ik = 1:size(obj.Parent.ICMS_Onset_Latency,2)
               tOnset = ones(1,2) * obj.Parent.ICMS_Onset_Latency(ii,ik) * 1e3;
               if obj.Parent.ICMS_Channel_Index(ik) == obj.Index
                  line(tOnset,Y,...
                     'Color','m',...
                     'LineStyle','-',...
                     'LineWidth',2);
               else
                  line(tOnset,Y,...
                     'Color','m',...
                     'LineStyle','--',...
                     'LineWidth',1.5);
               end
            end
         end
         
         % Axes X-scale is in milliseconds
         tStart = obj.Parent.Solenoid_Onset_Latency * 1e3;
         tStop = obj.Parent.Solenoid_Offset_Latency * 1e3;
         if numel(tStart) ~= numel(tStop)
            error('Something is wrong, mismatch in parsed number of solenoid onset (%g) vs offset (%g) pulses.',...
               numel(tStart),numel(tStop));
         end
         
         % Superimpose PATCH rectangle graphics objects where there would
         % be expected SOLENOID stimuli
         for ii = 1:numel(tStart)
            X = [tStart(ii),tStop(ii)];
            [x,y] = solChannel.getGraphicsRectXY(X,Y);
            patch(x,y,[0.25 0.25 0.25],'FaceAlpha',0.3,'EdgeColor','none');
         end
         
         % Change the color of the graphics objects depending on whether
         % this is a STIMULATION channel for ICMS
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
      
      % Return figure handle to peri-event LFP (average) for this channel
      function fig = avgLFPplot(obj,trialType,startStop,ii,makeNewFig)
         if isempty(obj)
            fig = [];
            return;
         end
         
         if nargin < 5
            makeNewFig = true;
         end
         if nargin < 4
            ii = 1;
         end
         if nargin < 3
            edges = obj.getSpikeBinEdges;
            startStop = [edges(1), edges(end)];
         end
         if nargin < 2
            trialType = cfg.TrialType('All');
         end         
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; avgLFPplot(obj(ii),trialType,startStop,ii,makeNewFig)];
            end
            return;
         end
         
         if isempty(obj.Parent.Trials)
            fig = [];
            fprintf(1,'Trial times not yet parsed for %s (%s).\n',obj.Parent.Name,obj.Name);
            return;
         end
         
         pars = cfg.default('ds');
         if isempty(obj.fs_d)
            in = load(obj.ds,'fs');
            obj.fs_d = in.fs;
         end
         
         
         [lfp,t] = obj.getAlignedLFP(trialType);
         
         if makeNewFig
            fig = figure('Name',sprintf('%s: %s average LFP (%s trials)',...
               obj.Parent.Name,obj.Name,char(trialType)),...
               'Color','w',...
               'Units','Normalized',...
               'Position',obj.Parent.getFigPos(ii));
         end
         
         mu = mean(lfp,1);
         sd = std(lfp,[],1) ./ sqrt(size(mu,1));
         
         p = plot(t,mu,...
            'Color',pars.col{obj.Hemisphere},...
            'LineWidth',pars.lw);
         
         xlim(pars.xlimit);
         ylim(pars.ylimit);
      
         obj.addStimulusMarkers(gca,p);
         solChannel.addAxesLabels(gca,obj.Name,'Time (ms)','LFP (\muV)');

         errbary = [mu + sd, fliplr(mu - sd)];
         errbarx = [t, fliplr(t)];
         patch(errbarx,errbary,pars.col{obj.Hemisphere},...
            'FaceAlpha',0.3,...
            'EdgeColor','none',...
            'FaceColor',pars.col{obj.Hemisphere});
         
      end
      
      % Return figure handle to average INSTANTANEOUS FIRING RATE (IFR;
      % spike rate) in alignment to TRIALS
      function fig = avgIFRplot(obj,trialType,startStop,ii,makeNewFig)
         if isempty(obj)
            fig = [];
            return;
         end
         
         if nargin < 5
            makeNewFig = true;
         end
         if nargin < 4
            ii = 1;
         end
         if nargin < 3
            edges = obj.getSpikeBinEdges;
            startStop = [edges(1), edges(end)];
         end
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; avgIFRplot(obj(ii),trialType,startStop,ii,makeNewFig)];
            end
            return;
         end
         
         
         
         if isempty(obj.Parent.Trials)
            fig = [];
            fprintf(1,'Trial times not yet parsed for %s (%s).\n',obj.Parent.Name,obj.Name);
            return;
         end
         
         if isempty(obj.ifr)
            obj.ifr = cfg.default('rate');
         end
         pars = cfg.default('ifr');
         
         if isempty(obj.fs_d)
            obj.getfs_d;
         end
         tvec = startStop(1):(1/obj.fs_d):startStop(2); % relative sample times
         [ifr,t] = obj.getAlignedIFR(trialType);
         ifr = sqrt(abs(ifr));
         ifr = (ifr - mean(ifr,2)) ./ std(ifr,[],1);
%          tvec = obj.edges(1:(end-1)) + mode(diff(obj.edges))/2;
%          binCounts = obj.getBinnedSpikes;
%          ifr = utils.fastsmooth(binCounts,15,'pg',0,1);
         
         if makeNewFig
            fig = figure('Name',sprintf('%s: %s average LFP (%s trials)',...
               obj.Parent.Name,obj.Name,char(trialType)),...
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
         solChannel.addAxesLabels(gca,obj.Name,'Time (ms)','IFR');

         errbary = [mu + sd, fliplr(mu - sd)];
         errbarx = [t, fliplr(t)];
         patch(errbarx,errbary,pars.col{obj.Hemisphere},...
            'FaceAlpha',0.3,...
            'EdgeColor','none',...
            'FaceColor',pars.col{obj.Hemisphere});
         
      end
      
      % Return figure handle to peri-event time histogram (PETH) for 
      % spiking on this channel
      function fig = PETH(obj,edges,trialType,ii,makeNewFig)
         if isempty(obj)
            fig = [];
            return;
         end
         
         if nargin < 5
            makeNewFig = true;
         end
         if nargin < 4
            ii = 1;
         end
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; PETH(obj(ii),edges,trialType,ii,makeNewFig)];
            end
            return;
         end
         
         if isempty(obj.Parent.Trials)
            fig = [];
            fprintf(1,'Trial times not yet parsed for %s (%s).\n',obj.Parent.Name,obj.Name);
            return;
         end
         
         col = cfg.default('barcols');
         obj.edges = edges;
         tvec = edges(1:(end-1))+(mode(diff(edges))/2);
         
         binCounts = sum(obj.getBinnedSpikes(trialType),1);         
                  
         if makeNewFig
            fig = figure('Name',sprintf('%s: %s (%s) PETH',...
               obj.Parent.Name,obj.Name,cfg.TrialType(trialType)),...
               'Color','w',...
               'Units','Normalized',...
               'Position',obj.Parent.getFigPos(ii));
         end
         
         b = bar(tvec*1e3,mean(binCounts,1),1,...
            'FaceColor',col{obj.Hemisphere},...
            'EdgeColor','none');
         
         xlim([obj.edges(1) obj.edges(end)]*1e3);
         ylim(cfg.default('ylimit'));
      
         obj.addStimulusMarkers(gca,b);
         if ii == 23
            solChannel.addAxesLabels(gca,obj.Name,'Time (ms)','Count');
         else
            solChannel.addAxesLabels(gca,obj.Name);
         end
      end
      
      % Plot SPIKE RASTER of spike instants across trials for this channel
      % relative to TRIAL alignment. Spike times are represented as
      % vertical bars.
      function plotRaster(obj,trialType,tPre,tPost,binWidth)
         if isempty(obj)
            fig = [];
            return;
         end
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if nargin == 5
            setSpikeBinEdges(obj,tPre,tPost,binWidth);
         end

         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               plotRaster(obj(ii),trialType);
            end
            return;
         end
         
         if isempty(obj.Parent.Trials)
            fig = [];
            fprintf(1,'Trial times not yet parsed for %s (%s).\n',obj.Parent.Name,obj.Name);
            return;
         end
         
         col = cfg.default('barcols');
         spikes = obj.getBinnedSpikes;
         edges = obj.getSpikeBinEdges;

         fig = figure('Name',sprintf('%s: %s Raster (%s trials)',...
            obj.Parent.Name,obj.Name,char(trialType)),...
            'Color','w',...
            'Units','Normalized',...
            'Position',[0.1 0.1 0.8 0.8]);

         [ax,h] = utils.plotSpikeRaster(logical(spikes),...
            'PlotType','vertline',...
            'rasterWindowOffset',edges(1),...
            'TimePerBin',mode(diff(edges)),...
            'FigHandle',fig,...
            'LineFormat',struct('Color',col{obj.Hemisphere},...
                                'LineWidth',1.5,...
                                'LineStyle','-'));         
      
         obj.addStimulusMarkers(ax,h,1);
         solChannel.addAxesLabels(ax,obj.Name,'Time (sec)','Trial');
         
         if ~isempty(obj.Parent)
         
            subf = cfg.default('subf');
            id = cfg.default('id');

            outpath = fullfile(obj.Parent.folder,[obj.Parent.Name subf.figs],subf.rasterplots);
            if exist(outpath,'dir')==0
               mkdir(outpath);
            end
            
            savefig(fig,fullfile(outpath,[obj.Name id.rasterplots '_' char(trialType) '.fig']));
            saveas(fig,fullfile(outpath,[obj.Name id.rasterplots '_' char(trialType) '.png']));
            delete(fig);
         end
      end
      
   end
   
   % Static methods
   methods (Static = true)
      % Add labels to a given axes. 'ax' can be an array of axes handles,
      % in which case titleString/xLabelString/yLabelString may each be a
      % char (same for all axes in array), titleString may be a cell array
      % with the same number of cell elements as elements in 'ax' array,
      % and xLabelString/yLabelString can be either both char vectors (same
      % label for all plots) or each be a cell array of equal length to
      % number of elements in 'ax'.
      function addAxesLabels(ax,titleString,xLabelString,yLabelString)
         % Parse input arguments
         if nargin < 4
            yLabelString = [];
         end
         if nargin < 3
            xLabelString = [];
         end
         if nargin < 2
            titleString = [];
         end
         
         % Handle arrays of axes inputs
         if numel(ax) > 1
            if iscell(titleString) 
               if iscell(xLabelString) 
                  for i = 1:numel(ax)
                     solChannel.addAxesLabels(ax(i),...
                        titleString{i},...
                        xLabelString{i},...
                        yLabelString{i});
                  end
               else
                  for i = 1:numel(ax)
                     solChannel.addAxesLabels(ax(i),...
                        titleString{i},...
                        xLabelString,...
                        yLabelString);
                  end
               end
            else
               for i = 1:numel(ax)
                  solChannel.addAxesLabels(ax(i),...
                     titleString,xLabelString,yLabelString);
               end
            end
            return;
         end
         
         % Set axes properties
         ax.Title.String = titleString;
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
      
      % Wrapper to return any number of configured default fields
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
      
      % Return [x,y] coordinates for vertices of a graphics rectangle,
      % given inputs X & Y that are each 2-element vectors that specify the
      % max and min bounds of the rect in X-Y dims.
      function [x,y] = getGraphicsRectXY(X,Y)
         x = [X(1), X(1), X(2), X(2)];
         y = [Y(1) Y(2) Y(2) Y(1)];
         
      end
   end
   
   % Private "helper" methods
   methods (Access = private)
      % Parse Channel Index for object or each element in object array
      function parseChannelIndex(obj)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).parseChannelIndex;
            end
            return;
         end
         
         ch_ord = obj.native_order + 1; % Native order is zero-indexed
         ch_port = obj.port_number - 1; % If Port "1" don't offset
         
         % Total number of channels is parsed from parent Layout
         nCh_total = numel(obj.Parent.Layout);
         
         obj.Index = ch_ord + (ch_port * nCh_total);
      end
      
      % Parse Channel depth for object or each element in object array
      function parseChannelLocation(obj)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).parseChannelDepth;
            end
            return;
         end
         
         % Set the Hemisphere
         obj.Hemisphere = cfg.Hem(obj.port_number);
         
         % Recordings all performed with rows indicating depth
         rec_layout_ord = obj.custom_order;
         [n,a,b] = solChannel.getDefault('nshank','spacing','offset');
         
         % Compute depth "index" of this site, based on # shanks (recording
         % order from custom_order is incremented by elements of rows
         % first, then by columns (e.g. [0, 1, 2, 3,
         %                               4, 5, 6, 7] indexing).
         x = floor(rec_layout_ord/n); % "Row Index"
         
         obj.Depth = a*x + b;
      end
      
      % Associate individual channel *.mat files with this class object so
      % the correct file can be pointed to for any of the data access
      % methods, to prevent the whole file from being stored in memory at
      % once.
      function setFileAssociations(obj,subf,id)
         % Parse input args
         if nargin < 3
            subf = cfg.default('subf');
         end
         
         if nargin < 2
            id = cfg.default('id');
         end
         
         % Handle array of object inputs
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).setFileAssociations(subf,id);
            end
            return;
         end
         
         % Set all file associations
         obj.setRaw(subf.raw,id.raw);
         obj.setFilt(subf.filt,id.filt);
         obj.setDS(subf.ds,id.ds);
         obj.setSpikes(subf.spikes,id.spikes);
         obj.setStims(subf.dig,id.stim);
         obj.setRate(subf.rate,id.rate,cfg.default('do_rate_estimate'));
      end
   end
end