classdef solChannel < handle
   %SOLCHANNEL  Organization object for data at the individual-channel level
   %
   %  obj = solChannel(solBlockObj,info);
   
   % PROPERTIES
   % Immutable properties set on object construction
   properties (GetAccess = public, SetAccess = immutable, Hidden = false)
      Name           % String name of electrode recording channel
      Parent         % SOLBLOCK object handle (experiment)
   end
   
   % Properties with public `get` access, but must be set by class method
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      Area           % Recording area ("RFA", "CFA", "S1", etc.)
      AP                   (1,1) double = nan       % electrode anteroposterior distance from Bregma (+ == rostral; anterior)
      Depth                (1,1) double = nan       % Site depth, relative to dorsal surface (microns)
      Hemisphere     % Left or Right hemisphere
      Impedance            (1,1) double = nan       % electrode impedance (kOhms)
      Probe                (1,1) struct = struct('AP',[],'ML',[],'TipDepth',[],'Angle',[]); % Struct with data about this probe
      ML                   (1,1) double = nan       % electrode mediolateral distance from Bregma (+ == lateral)
      Stim_Distance_table % Table with distances from stim channel
                          % -> If multiple stimulation sites, then there is
                          %    a new row for each channel. Variables are:
                          %      * Stim_Channel
                          %      * AP (anteroposterior offset)
                          %      * ML (mediolateral offset)
                          %      * DV (dorsoventral offset)
                          %      * Distance (Euclidean distance)
   end
   
   % Properties with public `get` access, but hidden and must be set by class method
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
   
   % Immutable properties that are not displayed in public properties list
   properties (GetAccess = public, SetAccess = immutable, Hidden = true)
      port_number    % PROBE used for this recording
      native_order   % Original channel order on INTAN RHS
      custom_order   % CUSTOM channel order used for acquisition on RHS
      fs             % Original sample frequency during recording
   end
   
   % METHODS
   % Class constructor and overloaded methods
   methods
      % Class constructor for SOLCHANNEL object
      function obj = solChannel(block,info,locData)
         %SOLCHANNEL Constructor for `solChannel` object
         %
         % obj = solChannel(solBlockObj,info);
         % obj = solChannel(solBlockObj,info,locData);
         %
         % Inputs
         %  solBlockObj - "Parent" `solBlock` object (must be provided)
         %                 -> Should be given as a scalar
         %  info        - struct with channel-specific "info" that is
         %                 obtained at the Block level (due to how the
         %                 recording information gets extracted). Therefore
         %                 this is passed as an input argument.
         %  locData     - (Optional) input table (from parent
         %                          `solBlock.Location_Table` property). If
         %                          not specified, then defaults are
         %                          assumed from `info` struct data.
         %
         % Output
         %  obj         - Scalar or array `solChannel` object that contains
         %                 data at the individual-channel level.
         
         if ~isa(block,'solBlock')
            if isscalar(block) && isnumeric(block)
               obj = repmat(obj,block,1); % Initialize empty array
               return;
            else
               error(['SOLENOID:' mfilename ':BadInput'],...
                  ['\n\t->\t<strong>[SOLCHANNEL]:</strong> ' ...
                   'Check ''block'' input argument (current class: %s)'],...
                  class(block));
            end
         end
         
         % Set public immutable properties
         obj.Parent = block;
         obj.Impedance = info.electrode_impedance_magnitude / 1000;
         obj.Name = string(info.custom_channel_name);
         
         % Set "hidden" properties
         obj.port_number = info.port_number;
         obj.native_order = info.native_order;
         obj.custom_order = info.custom_order;
         obj.fs = block.fs;
         
         % Parse channel's INDEX and LOCATION (Depth, Hemisphere)
         parseChannelIndex(obj);
         if nargin < 3
            parseChannelLocation(obj);
         else
            parseChannelLocation(obj,locData);
         end
            
         % Get configured defaults
         [subf,id] = solChannel.getDefault('subf','id');
         
         % Set file associations
         setFileAssociations(obj,subf,id);
         
      end  
   end
   
   % Public methods
   methods (Access = public)
      % Add markers denoting ICMS to a given axes
      function addStimulusMarkers(obj,ax,graphicsObj,pct)
         %ADDSTIMULUS Add markers denoting ICMS to a given axes
         %
         % addStimulusMarkers(obj,ax,graphicsObj,pct);
         %
         % Inputs
         %  obj         - Scalar or array of `solChannel` objects
         %  ax          - Axes to add stimulus markers to
         %                 -> If `obj` is array, then ax should be array of
         %                    equal size as `obj` (even if all are added to
         %                    same axes; in this case, just create an array
         %                    of the same ax to match size of `obj`)
         %  graphicsObj - (Optional); default is empty graphics placeholder
         %                 Currently handles changing color of either:
         %                 -> `matlab.graphics.chart.primitive.Line` or
         %                 -> `matlab.graphics.chart.primitive.Bar` 
         %  pct         - (Optional; default 0.9); percent of max. height
         %                    for superimposing timing indicator lines.
         
         if nargin < 4
            pct = solChannel.getDefault('indicator_pct');
         end
         
         if nargin < 3
            graphicsObj = gobjects(1);
         end
         
         if ~isscalar(obj)
            if isscalar(ax)
               ax = repelem(ax,numel(obj),1);
            end
            for i = 1:numel(obj)
               addStimulusMarkers(obj(i),ax(i),graphicsObj,pct);
            end
            return;
         end
         
         % Superimpose lines indicating timing of ICMS pulses
         set(ax,'NextPlot','add');
         Y = pct * get(ax,'YLim');
         for ii = 1:size(obj.Parent.ICMS_Onset_Latency,1)
            for ik = 1:size(obj.Parent.ICMS_Onset_Latency,2)
               tOnset = ones(1,2) * obj.Parent.ICMS_Onset_Latency(ii,ik) * 1e3;
               if obj.Parent.ICMS_Channel_Index(ik) == obj.Index
                  line(ax,tOnset,Y,...
                     'Color','m',...
                     'LineStyle','-',...
                     'LineWidth',2);
               else
                  line(ax,tOnset,Y,...
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
            error(['SOLENOID:' mfilename ':EventParsingError'],...
               ['\n\t->\t<strong>[ADDSTIMULUSMARKERS]:</strong> ' ...
                'Something is wrong, mismatch in parsed number ' ...
                'of solenoid onset (%g) vs offset (%g) pulses.'],...
               numel(tStart),numel(tStop));
         end
         
         % Superimpose PATCH rectangle graphics objects where there would
         % be expected SOLENOID stimuli
         for ii = 1:numel(tStart)
            X = [tStart(ii),tStop(ii)];
            [x,y] = solChannel.getGraphicsRectXY(X,Y);
            patch(ax,x,y,[0.25 0.25 0.25],...
               'FaceAlpha',0.3,'EdgeColor','none');
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
            fprintf(1,'Trial times not yet parsed for %s (%s).\n',...
               obj.Parent.Name,obj.Name);
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
            fprintf(1,'Trial times not yet parsed for %s (%s).\n',...
               obj.Parent.Name,obj.Name);
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
      
      % Return INSTANTANEOUS FIRING RATE (IFR; spike rate) aligned to TRIAL
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
      
      % Returns matrix of counts of binned spikes
      function binCounts = getBinnedSpikes(obj,trialType,tPre,tPost,binWidth)
         %GETBINNEDSPIKES Returns matrix of counts of binned spikes
         %
         % binCounts = getBinnedSpikes(obj);
         % binCounts = getBinnedSpikes(obj,trialType);
         % binCounts = getBinnedSpikes(obj,trialType,tPre,tPost);
         % binCounts = getBinnedSpikes(obj,trialType,tPre,tPost,binWidth);
         %
         % Inputs
         %  obj       - Scalar or array of `solChannel` objects
         %  trialType - (Optional) only get matrix for trials of
         %                 `TrialType`
         %  tPre      - (Optional) relative time (seconds) to start bins 
         %  tPost     - (Optional) relative time (seconds) to end bins
         %  binWidth  - (Optional) width of bins (seconds) for counting
         %                 spike times relative to trial onset
         % Output
         %  binCounts - Matrix of counts of binned spikes, where each row
         %              corresponds to a single trial
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if nargin == 5
            % Set the spike bin edges if this arg is given
            obj.setSpikeBinEdges(tPre,tPost,binWidth);
         end
         
         % Do we clip bin counts to one (per trial)?
         %  -> Makes more sense to do if looking at **sorted** single-unit
         %     activity
         %  -> For multi-unit activity, it's not inconceivable to see
         %     multiple spikes within a 2-ms epoch, simply due to the
         %     possibility of multiple sources generating said spikes.
         clipBinCounts = cfg.default('clip_bin_counts');
         
         edges = obj.getSpikeBinEdges;
         
         tSpike = getSpikes(obj);
         trials = obj.getTrials(trialType);
         binCounts = zeros(numel(trials),numel(edges)-1);
         
         for iT = 1:numel(trials)
            binCounts(iT,:) = histcounts(tSpike-trials(iT),edges);
         end
         
         if clipBinCounts
            binCounts = min(binCounts,1); % Clip to 1 spike per bin
         end
      end
      
      % Returns BANDPASS FILTERED (UNIT) data for this channel
      function [data,t] = getFilt(obj,ch,vec)
         %GETFILT Return bandpass filtered (unit) data for this channel
         %
         % [data,t] = getFilt(obj,ch,vec);
         %
         % Inputs
         %  obj - Scalar or array `solChannel` object
         %  ch  - Channel indices to use (indices into `obj` array)
         %  vec - "Time-Mask" index vector; if not supplied, returns the
         %        entire vector.
         %
         % Output
         %  data - Bandpass-filtered (unit) time-series signal
         %  t    - Times corresponding to samples of `data`
         
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
      function data = getSpikes(obj,ch,type)
         %GETSPIKES Returns spike point-process data for this channel
         %
         % data = getSpikes(obj);
         % data = getSpikes(obj,ch,type);
         %
         % Inputs
         %  obj  - Scalar or array of `solChannel` objects
         %  ch   - Indexing array for `obj` input (default is all `obj`)
         %  type - Can be: 'ts' (default; times) or 'wave' (spike snippets)
         %
         % Output
         %  data - Depends on `type` argument. If `type` is `ts` (default)
         %         then this returns a cell array of timestamps of spike
         %         peak times for each element of `obj` (unless a scalar
         %         `obj` is given in which case data is just the vector
         %         array of timestamps).
         %         If `type` is `wave` then this is a cell array of spike
         %         waveform snippets, where each row corresponds to a
         %         sequential corresponding timestamp of spike peak time.
         
         if nargin < 2
            ch = 1:numel(obj);
         end
         if nargin < 3
            type = 'ts';
         end
         if ~isscalar(obj)
            
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
      
      % Compute the instantaneous firing rate (IFR) and save to files
      function estimateRate(obj,ch)
         %ESTIMATERATE Estimate instantaneous firing rate (IFR) 
         %
         % estimateRate(obj);
         % estimateRate(obj,ch);
         %
         % Inputs
         %  obj - Scalar or array of `solChannel` objects
         %  ch  - (optional) indexing into `obj` input
         %
         % Output
         %  -- none -- Create IFR estimates in diskfiles associated with
         %             this `solChannel` object or each `solChannel` object
         %             in `obj` array.
         
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
      
      % Returns **channel** data table for convenient export of dataset
      function channelTable = makeTables(obj,probeDepth,tPre,tPost)
         %MAKETABLES Returns data table elements specific to `solChannel`
         %
         %  channelTable = makeTables(obj,trialData);
         %
         %  Inputs
         %     obj          - Scalar or Array of `solBlock` objects
         %     probeDepth   - Depth (mm) of total probe for this channel
         %
         %  Output
         %     channelTable - Table with the following variables:
         %        * `ChannelID`- (Unique) identifier for a single channel
         %        * `Channel`  - Channel index (1:32) for a given array
         %        * `Probe`    - Probe index (1:2)
         %        * `Hemisphere` - Indicates if probe is in left or right
         %                          hemisphere
         %        * `Area`       - Indicates if probe is in RFA/CFA/S1
         %        * `Impedance`  - Individual channel measured impedance
         %        * `AP`         - X-coordinate (mm) relative to bregma
         %                          (anteroposterior distance)
         %        * `ML`         - Y-coordinate (mm) relative to bregma
         %                          (mediolateral distance)
         %        * `Depth`      - Depth of recording channel (depends on
         %                          channels, which are at different depths
         %                          on individual recording shanks, as well
         %                          as the overall insertion depth)
         %        * `StimDistance` - Distance from ICMS site
         %        * `Spikes` - Binned spike counts relative to alignment 
         %                       for a single channel.
         %        * `LFP`    - LFP time-series relative to alignment for a
         %                       single channel.
         %        * `Notes` - Most-likely empty, but allows manual input of
         %                    notes or maybe a notes struct? Basically
         %                    something that lets you manually add "tags" 
         %                    to the data rows.
         
         if nargin < 3
            tPre = solChannel.getDefault('tpre');
         end
         
         if nargin < 4
            tPost = solChannel.getDefault('tpost');
         end
         
         % Since it can be an array, iterate/recurse over all the blocks
         if ~isscalar(obj)
            channelTable = table.empty; % Create empty data table to append
            if isscalar(probeDepth)
               probeDepth = repelem(probeDepth,size(obj));
            end
            for iChannel = 1:numel(obj)
               channelTable = [channelTable; ...
                  makeTable(obj(iChannel),probeDepth(iChannel))];
            end
            return;
         end
         
         % SolChannel stuff
         
         ChannelID = obj.Name;
         [Probe,Channel] = parseNameInfo(obj);
         
         Hemisphere = obj.Hemisphere;
         Depth = obj.Depth;
         Impedance = obj.Impedance;
         
         channelTable = table(ChannelID,Channel,Probe,...
            Hemisphere,Depth,Impedance);
         
         % Return all binned spikes (for all trials) on this channel
         Spikes = getBinnedSpikes(obj);
         
         
         
      end %%%% End of makeTables%%%%
  
      % Return figure handle to (channel) peri-event time histogram (PETH)
      function fig = PETH(obj,edges,trialType,ii,h)
         %PETH Return figure handle to (channel) peri-event time histogram
         %
         % fig = PETH(obj,edges,trialType);
         % fig = PETH(obj,edges,trialType,ii);
         % fig = PETH(obj,edges,trialType,ii,h);
         %
         % Inputs
         %  obj        - Scalar or array of `solChannel` objects
         %  edges      - Bin edges for generating histogram counts
         %  trialType  - Enumerated class specifying  type of trials to
         %               generate the counts for in the PETH figure
         %  ii         - (Optional) index indicating channel index within
         %                          some parent iterator
         %  h          - (Optional) default is empty (in which case new
         %                  figure is generated); can be passed as graphics
         %                  container to put the new PETH plot in
         %
         % Output
         %  fig        - `matlab.ui.Figure` handle object that
         %                contains the PETH plot
         %
         % See also: solBlock.batchPETH
         
         if isempty(obj)
            fig = [];
            return;
         end
         
         if nargin < 5
            h = [];
         end
         if nargin < 4
            ii = 1;
         end
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; PETH(obj(ii),edges,trialType,ii,h)];
            end
            return;
         end
         
         if isempty(obj.Parent.Trials)
            fig = [];
            fprintf(1,...
               'Trial times not yet parsed for %s (%s).\n',...
               obj.Parent.Name,obj.Name);
            return;
         end
         
         col = cfg.default('barcols');
         obj.edges = edges;
         tvec = edges(1:(end-1))+(mode(diff(edges))/2);
         
         binCounts = sum(obj.getBinnedSpikes(trialType),1);
         [axParams,yLim,labelsIndex] = solChannel.getDefault(...
            'axparams','ylimit','labelsindex');
         if isempty(h)
            fig = figure('Name',sprintf('%s: %s (%s) PETH',...
               obj.Parent.Name,obj.Name,cfg.TrialType(trialType)),...
               'Color','w',...
               'Units','Normalized',...
               'Position',obj.Parent.getFigPos(ii));
            ax = axes(fig,axParams{:});
         else
            switch class(h)
               case 'matlab.ui.Figure'
                  fig = h;
                  ax = axes(fig,axParams{:});
               case 'matlab.graphics.axis.Axes'
                  ax = h;
                  if isa(h.Parent,'matlab.ui.Figure')
                     fig = h.Parent;
                  else
                     fig = gcf;
                  end
               case 'matlab.ui.container.Panel'
                  if isa(h.Parent,'matlab.ui.Figure')
                     fig = h.Parent;
                  else
                     fig = gcf;
                  end
                  ax = axes(h,axParams{:});
               otherwise
                  error(['SOLENOID:' mfilename ':BadContainer'],...
                     ['\n\t->\t<strong>[PETH]:</strong> ' ...
                      'Unexpected container class (`h`): ''%s''\n' ...
                      '\t\t\t\t(Should be figure, axes, or panel)\n'],...
                      class(h));
            end
         end
         
         b = bar(ax,tvec*1e3,mean(binCounts,1),1,...
            'FaceColor',col{obj.Hemisphere},...
            'EdgeColor','none');
         
         xlim(ax,[obj.edges(1) obj.edges(end)]*1e3);
         ylim(ax,yLim);
         
         addStimulusMarkers(obj,ax,b);
         if ii == labelsIndex
            % Only add the actual <x,y> abscissa labels to one subplot
            solChannel.addAxesLabels(ax,obj.Name,...
               'Time (ms)','Count');
         else
            solChannel.addAxesLabels(ax,obj.Name);
         end
      end
      
      % Plot spike times in rows (trials) as vertical bars (impulses)
      function fig = plotRaster(obj,trialType,tPre,tPost,batch,binWidth)
         %PLOTRASTER Plot spike raster of spikes across trials for channel
         %
         % fig = plotRaster(obj);
         % fig = plotRaster(obj,trialType,tPre,tPost,batch,binWidth);
         %
         % Inputs
         %  obj       - Scalar or array of `solChannel` objects
         %  trialType - `cfg.TrialType` of which trials to include
         %  tPre      - Time (sec) prior to alignment
         %  tPost     - Time (sec) after alignment
         %  batch     - (default is false): if set to true, delete `fig`
         %                 after saving it for each element of `obj`
         %  binWidth  - Time (sec) width of each raster "bin"
         %
         % Output
         %  fig       - Array of figure handles corresponding to elements
         %                 of `obj`
         if isempty(obj)
            fig = gobjects(1);
            return;
         end
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if nargin < 3
            tPre = solChannel.getDefault('tpre');
         end
         
         if nargin < 4
            tPost = solChannel.getDefault('tpost');
         end
         
         if nargin < 5
            batch = false;
         end
         
         if nargin >= 6
            setSpikeBinEdges(obj,tPre,tPost,binWidth);
         end
         
         if numel(obj) > 1
            fig = gobjects(size(obj));
            for ii = 1:numel(obj)
               fig(ii) = plotRaster(obj(ii),trialType,tPre,tPost,batch);
            end
            return;
         end
         
         if isempty(obj.Parent.Trials)
            fig = gobjects(1);
            fprintf(1,...
               'Trial times not yet parsed for %s (%s).\n',...
               obj.Parent.Name,obj.Name);
            return;
         end
         
         col = cfg.default('barcols');
         spikes = obj.getBinnedSpikes;
         edges = obj.getSpikeBinEdges;
         
         fig = figure(...
            'Name',sprintf('%s: %s Raster (%s trials)',...
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
         
         if ~isempty(obj.Parent) && batch
            
            subf = cfg.default('subf');
            id = cfg.default('id');
            
            outpath = fullfile(obj.Parent.folder,...
               [obj.Parent.Name subf.figs],subf.rasterplots);
            if exist(outpath,'dir')==0
               mkdir(outpath);
            end
            
            savefig(fig,fullfile(outpath,...
               [obj.Name id.rasterplots '_' char(trialType) '.fig']));
            saveas(fig,fullfile(outpath,...
               [obj.Name id.rasterplots '_' char(trialType) '.png']));
            delete(fig);
         end
      end
      
      
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
      function parseChannelLocation(obj,locData)
         %PARSECHANNELLOCATION Parse channel location & depth 
         %
         % parseChannelLocation(obj);
         % parseChannelLocation(obj,locData);
         %
         % Inputs
         %  obj     - Scalar or array of `solChannel` objects
         %  locData - Table with probe location data
         %              -> If `obj` is array, then this should be passed as
         %                 a cell array of such tables, each element
         %                 corresponding to a matched element of `obj`
         %
         % Output
         %  -- none -- Makes association with correct channel location,
         %             depth, based on the name of the recording channel.
         
         if numel(obj) > 1
            if nargin < 2
               for ii = 1:numel(obj)
                  parseChannelDepth(obj(ii));
               end
            else
               for ii = 1:numel(obj)
                  parseChannelDepth(obj(ii),locData{ii});
               end
            end
            return;
         end
         
         Probe = parseNameInfo(obj);
         if nargin < 2 % If no `locData` use `cfg.default` values
            parseLayoutInfo(obj);
            [areaKey,thetaKey,mlKey,apKey] = solChannel.getDefault(...
               'areakey','thetakey','mlkey','apkey');
            obj.Area = areaKey.(Probe);
            obj.Hemisphere = cfg.Hem(obj.port_number);
            obj.Probe.Angle = thetaKey.(Probe);
            obj.Probe.ML = mlKey.(Probe);
            obj.Probe.AP = apKey.(Probe);
         else % Parse relevant properties from `locData` table
            locData = locData(ismember(locData.Probe,Probe),:);
            parseLayoutInfo(obj,locData.Depth(1));
            obj.Area = locData.Area{1};
            obj.Hemisphere = locData.Hemisphere{1};
            obj.Probe.Angle = locData.Angle(1);
            obj.Probe.AP = locData.AP(1);
            obj.Probe.ML = locData.ML(1);
         end % obj.Probe struct is now complete; still need channel loc
         
         % Relative to probe "center" coordinates, we can now estimate the
         % actual channel AP and ML coordinates using the rotation angle of
         % the probe along with which shank it is on. 
         [shankSpacing,nShank] = solChannel.getDefault(...
            'shankspacing','nshank');
         
         % First, determine which shank it was on so that we can get the
         % rotation radius. The radius for an even number of shanks
         % will be [shank - (1 + nShank)/2] * shankSpacing, where `shank`
         % is the shank index. 
         iShank = rem(obj.custom_order,nShank)+1; % Convert to 1-indexed
         r = (iShank - ((1 + nShank)/2)) * shankSpacing; % Radius
         
         % For `theta = 0` it would be aligned perfectly to midline. In
         % that case, `
      end
      
      % Parse default `locData` table based on other info
      function parseLayoutInfo(obj,tipDepth)
         %PARSELAYOUTINFO Return default `locData` based on info
         %
         % parseLayoutInfo(obj);
         % parseLayoutInfo(obj,tipDepth);
         %  
         % Inputs
         %  obj      - Scalar `solChannel` object
         %  tipDepth - (Optional) Depth of tip (microns); if provided, then
         %                        value used in `depthkey` variable from
         %                        `cfg.default` is overridden.
         %
         % Output
         %  -- none -- Updates `solChannel.Depth` property
         %
         % See also: solChannel.parseChannelLocation, solBlock.setChannels

         % Load relevant defaults
         [channelSpacing,tipOffset,depthKey,nShank,nRow] = ...
            solChannel.getDefault(...
               'spacing','offset','depthkey','nshank','nchannelpershank');
         % Use `Probe` as key for assignment
         Probe = parseNameInfo(obj);  
         % If `tipDepth` isn't given, use default value from key
         if nargin < 2
            tipDepth = depthKey.(Probe);
         end         

         % Note: This method will fail if `nchannelpershank` is not set
         %       correctly, which is only a consideration for the earliest
         %       pilot rats (when there was only 16-channels instead of
         %       32-channels per probe) -- Those need to have
         %       `nchannelpershank` and `spacing` in cfg.default updated.
         %
         % Compute depth "index" of this site, based on # shanks (recording
         % order from custom_order is incremented by elements of rows
         % first, then by columns (e.g. [0, 1, 2, 3,
         %                               4, 5, 6, 7] indexing).
         % Recordings all performed with rows indicating depth
         rowsFromBottom = nRow - floor(obj.custom_order/nShank); % "Row Index"
         deepestChannel = (tipDepth - tipOffset);
         obj.Depth = deepestChannel - channelSpacing*rowsFromBottom;
      end
      
      % Parse Probe name and Channel index from `obj.Name`
      function [Probe,Channel] = parseNameInfo(obj)
         %PARSENAMEINFO Return port identifier and channel index from name
         %
         % [Probe,Channel] = parseNameInfo(obj);
         %
         % Inputs
         %  obj     - Scalar or array of `solChannel` objects
         %
         % Output
         %  Probe   - String corresponding to "Port" (leading element of
         %            `obj.Name`). If `obj` is an array, returned as array
         %            of same size with matching elements.
         %  Channel - Numeric index (1-indexed) corresponding to index on
         %            this probe based on obj.Name. If `obj` is an array,
         %            then this is returned as an array of same size.
         
         if ~isscalar(obj)
            Probe = strings(size(obj));
            Channel = nan(size(obj));
            for i = 1:numel(obj)
               [Probe(i),Channel(i)] = parseNameInfo(obj(i));
            end
            return;
         end
         pInfo = strsplit(ChannelID,'-');
         Probe     = pInfo(1);
         Channel   = str2double(pInfo(2)) + 1; % Account for zero-index
         
      end
      
      % Associate individual channel *.mat files
      function setFileAssociations(obj,subf,id)
         %SETFILEASSOCIATIONS Associate individual channel *.mat files
         %
         % setFileAssociations(obj,subf,id);
         %
         % Inputs
         %  obj  - scalar or array of `solBlock` object
         %  subf - struct where each field corresponds to a particular
         %           sub-folder name or tag to check at the "Block"
         %           hierarchical level
         %  id   - struct where each field corresponds to a particular
         %           "file id" tag that is used for each file of the
         %           corresponding fieldname type
         %
         % Output
         %  -- none -- Creates associations with the correct files in the
         %             properties of solBlock `obj` or array of such
         %             objects.
         
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
   
   % Static methods
   methods (Static = true)
      % Add labels to a given axes
      function addAxesLabels(ax,titleString,xLabelString,yLabelString)
         %ADDAXESLABELS Add labels to a given axes
         %
         % solChannel.addAxesLabels(ax);
         % solChannel.addAxesLabels(ax,titleString);
         % solChannel.addAxesLabels(ax,titleString,xLabelString,yLabelString);
         %
         % Inputs
         %  ax           - `matlab.graphics.axis.Axes` object or array
         %  titleString  - (Optional) string to add as title of `ax`
         %        -> If `ax` is an array, can either be a single string or
         %           a cell array of chars or strings that matches the size
         %           of obj (same is true for other 2 input args).
         %  xLabelString - (Optional) string to add as xLabel
         %  yLabelString - (Optional) string to add as yLabel
         %        -> Must match dimension of `xLabelString`
         %
         % Output
         %  -- None -- Updates `ax` with formatted labels.
         
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
         fontParams = solChannel.getDefault('fontparams');
         % Set axes labels with correct formatting
         set(ax.Title,'String',titleString,...
            'FontSize',16,fontParams{:});
         set(ax.XLabel,'String',xLabelString,...
            'FontSize',14,fontParams{:});
         set(ax.YLabel,'String',yLabelString,...
            'FontSize',14,fontParams{:});
      end
      
      % Return empty `solChannel` object
      function obj = empty()
         %EMPTY  Return empty `solChannel` object
         %
         % obj = solChannel.empty();
         %
         % Use this to initialize an empty array of `solChannel` for
         % concatenation, for example.
         
         obj = solChannel(0);
      end
      
      % Wrapper to return any number of configured default fields
      function varargout = getDefault(varargin)
         %GETDEFAULT Return defaults parameters for `solChannel`
         %
         %  varargout = solChannel.getDefault(varargin);
         %  e.g.
         %     param = solChannel.getDefault('paramName');
         %     [p1,...,pk] = solChannel.getDefault('p1Name',...,'pkName');
         %
         %  Inputs
         %     varargin - Any of the parameter fields in the struct 
         %                delineated in `cfg.default`
         %
         %  Wrapper function to get variable number of default fields
         %
         %  See Also: cfg.default
         
         % Parse input
         if (nargin > nargout) && (nargout > 0)
            error(['SOLENOID:' mfilename ':TooManyInputs'],...
               ['\n\t->\t[GETDEFAULT]: ' ...
                'More inputs specified than requested outputs']);
         elseif (nargin < nargout)
            error(['SOLENOID:' mfilename ':TooManyInputs'],...
               ['\n\t->\t[GETDEFAULT]: ' ...
                'More outputs requested than inputs specified']);
         end
         
         % Collect fields into output cell array
         if nargout > 0
            varargout = cell(1,nargout);
            [varargout{:}] = cfg.default(varargin{:});
         else
            cfg.default(varargin{:});
         end
      end
      
      % Return [x,y] for 2D rectangle vertices
      function [x,y] = getGraphicsRectXY(X,Y)
         %GETGRAPHICSRECTXY Return [x,y] for 2D rectangle vertices
         %
         % [x,y] = solChannel.getGraphicsRectXY(X,Y);
         %
         % Inputs
         %  X - 2-element vector that is [lower, upper] bounds on x-dim
         %  Y - 2-element vector that is [lower, upper] bounds on y-dim
         %
         % Output
         %  x - 4-element vector to be used for rectangle vertices x-dim
         %  y - 4-element vector to be used for rectangle vertices y-dim
         
         x = [X(1), X(1), X(2), X(2)];
         y = [Y(1) Y(2) Y(2) Y(1)];
         
      end
   end
end