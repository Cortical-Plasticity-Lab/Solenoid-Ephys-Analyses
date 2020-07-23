classdef solChannel < handle
   %SOLCHANNEL  Handle class to organize data at the individual-channel level
   %
   %  obj = solChannel(solBlockObj,info);
   %
   %  Note that this object can only be constructed via call from
   %  solBlock object.
   %
   % solChannel Properties
   %  Name       - String name of electrode recording channel ("A-###" or "B-###")
   %  Parent     - Parent solBlock object handle (experiment)
   %  Area       - Recording area ("RFA", "CFA", "S1", etc.)
   %  AP         - Electrode anteroposterior distance from Bregma (mm)
   %  Depth      - Electrode depth, relative to dorsal surface (microns)
   %  Hemisphere - "Left" or "Right" hemisphere
   %  Impedance  - Electrode impedance (kOhms)
   %  Probe      - Struct containing information about probe center location, depth, and angle/orientation
   %  ML         - Electrode mediolateral distance from Bregma (mm)
   %  StimData   - Table with distances from ICMS stimulation electrode
   %
   % solChannel Methods
   %  solChannel - Class constructor for solChannel object
   %  makeTables - Method to return channel-level table information
   %
   % See also: solRat, solBlock
   
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
      Probe                (1,1) struct = struct('AP',[],'ML',[],'TipDepth',[],'Angle',[],'Orientation',""); % Struct with data about this probe
      ML                   (1,1) double = nan       % electrode mediolateral distance from Bregma (+ == lateral)
      StimData            % Table with distances from stim channel
                          % -> If multiple stimulation sites, then there is
                          %    a new row for each channel. Variables are:
                          %      * Name (`obj.Name` of stim channel)
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
   % Restricted access: class constructor, set stim distance
   methods (Access = {?solChannel, ?solBlock})
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
      
      % Assign distance to ICMS site(s)
      function setStimChannelDistance(obj,Name,AP,ML,Depth)
         %SETSTIMCHANNELDISTANCE  Sets distance from stimulation site(s)
         %
         % setStimChannelDistance(obj,Name,AP,ML,Depth);
         % setStimChannelDistance(obj,"None",nan,nan,nan); 
         %  -> If no stim channel
         %
         % Inputs
         %  obj   - Scalar or array of `solChannel` objects
         %  Name  - `solChannel.Name` corresponding to `solChannel` stim
         %            object or objects (if array). All input arguments
         %            should correspond to the number of stim channels (so
         %            each input arg, aside from `obj` should have the same
         %            number of elements).
         %  AP    - Distance (anteroposterior from Bregma; mm)          %            per stim site)
         %  ML    - Distance (mediolateral from Bregma; mm)
         %  Depth - Distance (from dorsal surface of brain; microns)
         %
         % Output
         %  -- none -- Updates the `solChannel.StimData`
         %             property, which has one row per stim site (or only
         %             one row if no stimulation site)
         
         if ~isscalar(obj)
            for i = 1:numel(obj)
               setStimChannelDistance(obj(i),Name,AP,ML,Depth);
            end
            return;
         end
         
         AP = bsxfun(@minus,obj.AP,AP);
         ML = bsxfun(@minus,obj.ML,ML);
         % By convention, negative value for depth would indicate that the
         % site is more superficial to the stim site.
         DV = bsxfun(@minus,obj.Depth,Depth) .* 1e-3; % scale to mm 
         Distance = sqrt((AP + ML + DV).^2);
         stimTable = table(Name,Distance,AP,ML,DV);
         stimTable.Properties.Description = ...
            'Distance (mm) to site(s) delivering ICMS';
         stimTable.Properties.VariableUnits = ...
           {'Channel','mm','mm','mm','mm'};
         stimTable.Properties.VariableDescriptions = ...
           {'Name of ICMS channel',...
            'Euclidean distance from stim site',...
            'Anteroposterior distance relative to stim site (+ == rostral)',...
            'Mediolateral distance relative to stim site (+ == lateral)',...
            'Dorsoventral distance relative to stim site (+ == ventral)'};
         stimTable.Properties.UserData = struct('type','StimDistance');
         obj.StimData = stimTable;
      end
   end
   
   % Overloaded and most-used methods
   methods      
      % Return LFP aligned to TRIALS for this channel
      function [data,t] = getAlignedLFP(obj,trialType)
         %GETALIGNEDLFP Return LFP aligned to trials for this channel
         %
         %  [data,t] = getAlignedLFP(obj);
         %  [data,t] = getAlignedLFP(obj,trialType);
         %  
         % Inputs
         %  obj       - Scalar or array of `solChannel` objects
         %  trialType - (Optional) if not specified, returns all trials;
         %                          otherwise, use this as `cfg.TrialType`
         %                          element to enumerate subset of trials
         %                          to return.
         % Output
         %  data      - Data matrix, where rows are trials and columns are
         %              time-samples. All data corresponds to a single
         %              channel. If `obj` is an array, then this is
         %              returned as a cell array with each element
         %              corresponding to matched elements of `obj` array
         %  t         - Vector of times corresponding to columns of `data`
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if ~isscalar(obj)
            data = cell(size(obj));
            for i = 1:numel(obj)
               if i == 1
                  [data{i},t] = getAlignedLFP(obj(i),trialType);
               else
                  data{i} = getAlignedLFP(obj(i),trialType);
               end
            end
            return;
         end
         
         data = getLFP(obj);
         edges = getSpikeBinEdges(obj); %#ok<*PROP>
         
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
         %GETALIGNEDIFR Return IFR aligned to trials for this channel
         %
         %  [data,t] = getAlignedIFR(obj);
         %  [data,t] = getAlignedIFR(obj,trialType);
         %  
         % Inputs
         %  obj       - Scalar or array of `solChannel` objects
         %  trialType - (Optional) if not specified, returns all trials;
         %                          otherwise, use this as `cfg.TrialType`
         %                          element to enumerate subset of trials
         %                          to return.
         % Output
         %  data      - Data matrix, where rows are trials and columns are
         %              time-samples. All data corresponds to a single
         %              channel. If `obj` is an array, then this is
         %              returned as a cell array with each element
         %              corresponding to matched elements of `obj` array
         %  t         - Vector of times corresponding to columns of `data`
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if ~isscalar(obj)
            data = cell(size(obj));
            for i = 1:numel(obj)
               if i == 1
                  [data{i},t] = getAlignedIFR(obj(i),trialType);
               else
                  data{i} = getAlignedIFR(obj(i),trialType);
               end
            end
            return;
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
         
         
         switch nargin
            case 1
               trialType = cfg.TrialType('All');
               if ~isscalar(obj)
                  binCounts = cell(size(obj));
                  for i = 1:numel(obj)
                     binCounts{i} = getBinnedSpikes(obj,trialType);
                  end
                  return;
               end
            case 2
               if ~isscalar(obj)
                  binCounts = cell(size(obj));
                  for i = 1:numel(obj)
                     binCounts{i} = getBinnedSpikes(obj,trialType);
                  end
                  return;
               end
            case 3
               if ~isscalar(obj)
                  binCounts = cell(size(obj));
                  for i = 1:numel(obj)
                     binCounts{i} = getBinnedSpikes(obj,trialType,tPre);
                  end
                  return;
               end
            case 4
               if ~isscalar(obj)
                  binCounts = cell(size(obj));
                  for i = 1:numel(obj)
                     binCounts{i} = getBinnedSpikes(obj,trialType,tPre,tPost);
                  end
                  return;
               end
            otherwise
               if ~isscalar(obj)
                  binCounts = cell(size(obj));
                  for i = 1:numel(obj)
                     binCounts{i} = getBinnedSpikes(obj,trialType,tPre,tPost,binWidth);
                  end
                  return;
               else
                  setSpikeBinEdges(obj,tPre,tPost,binWidth);
               end
         end
         
         % Do we clip bin counts to one (per trial)?
         %  -> Makes more sense to do if looking at **sorted** single-unit
         %     activity
         %  -> For multi-unit activity, it's not inconceivable to see
         %     multiple spikes within a 2-ms epoch, simply due to the
         %     possibility of multiple sources generating said spikes.
         clipBinCounts = solBlock.getDefault('clip_bin_counts');
         
         edges = getSpikeBinEdges(obj);
         
         tSpike = getSpikes(obj);
         trials = getTrials(obj,trialType,edges);
         binCounts = zeros(numel(trials),numel(edges)-1);
         
         for iT = 1:numel(trials)
            binCounts(iT,:) = histcounts(tSpike-trials(iT),edges);
         end
         
         if clipBinCounts % Default is set to false (2020-07-23)
            binCounts = min(binCounts,1); % Clip to 1 spike per bin
         end
      end
      
      % Returns **channel** data table for convenient export of dataset
      function channelTable = makeTables(obj,trialData,tPre,tPost)
         %MAKETABLES Returns data table elements specific to `solChannel`
         %
         %  channelTable = makeTables(obj,trialData);
         %  channelTable = makeTables(obj,trialData,tPre,tPost);
         %
         %  Inputs
         %     obj          - Scalar or Array of `solBlock` objects
         %     probeDepth   - Depth (mm) of total probe for this channel
         %     tPre         - Time (sec) prior to alignment event for data
         %                    to start accumulating
         %     tPost        - Time (sec) after alignment event for data to
         %                    stop accumulating
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
         
         % Since it can be an array, iterate/recurse over all the blocks
         if ~isscalar(obj)
            switch nargin
               case 2
                  channelTable = appendTables(obj,...
                     @(o,td)makeTables(o,td),...
                     trialData);
               case 3
                  channelTable = appendTables(obj,...
                     @(o,td,tpre)makeTables(o,td,tpre),...
                     trialData,tPre);
               otherwise
                  channelTable = appendTables(obj,...
                     @(o,td,pr,po)makeTables(o,td,pr,po),...
                     trialData,tPre,tPost);
            end
            return;
         end
         
         % Get `tPre` and `tPost` depending on # input args
         if nargin < 3
            [~,tPre,tPost] = getSpikeBinEdges(obj);
         elseif nargin < 4
            [~,~,tPost] = getSpikeBinEdges(obj);
         end
         
         % Get number of rows that this `channelTable` will be
         nTrial = numel(trialData);
         
         % SolChannel stuff
         ChannelID = obj.Name;
         [Probe,Channel] = parseNameInfo(obj);
         
         Hemisphere = obj.Hemisphere;
         Depth = obj.Depth;
         AP = obj.AP;
         ML = obj.ML;
         Impedance = obj.Impedance;
         stimTable = obj.StimData;
         nStim = size(stimTable,1);
         Stim_Ch = reshape(stimTable.Name,1,nStim);
         Stim_AP = reshape(stimTable.AP,1,nStim);
         Stim_ML = reshape(stimTable.ML,1,nStim);
         Stim_DV = reshape(stimTable.DV,1,nStim);
         Stim_Dist = reshape(stimTable.Distance,1,nStim);
         
         channelTable = table(ChannelID,Channel,Probe,...
            Hemisphere,Depth,AP,ML,Impedance,...
            Stim_Ch,Stim_AP,Stim_ML,Stim_DV,Stim_Dist);
         channelTable = repmat(channelTable,nTrial,1);
         
         % % Create "trialTable" for trial data to match channelTable % %
         trialTable = solChannel.trialData2Table(trialData,tPre,tPost,...
            obj.Parent.TotalDuration);
         
         % % Return "dataTable" with Spikes & LFP data % %
         dataTable = getDataTable(obj,tPre,tPost);
         
         % Concatenate trialTable with channels tables
         channelTable = [trialTable, channelTable, dataTable];
         
         % Convert some variables to categorical %
         channelTable.Hemisphere = categorical(...
            channelTable.Hemisphere,["Right","Left"]);
         channelTable.Probe = categorical(...
            channelTable.Probe,["A","B"]);
         
      end %%%% End of makeTables%%%%
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
      
      % Return figure handle to average IFR plots aligned to trials
      function fig = avgIFRplot(obj,trialType,startStop,ii,makeNewFig)
         %AVGIFRPLOT Return figure handle with IFR plotted for trials
         %
         % fig = avgIFRplot(obj);
         % fig = avgIFRplot(obj,trialType);
         % fig = avgIFRplot(obj,trialType,startStop);
         % fig = avgIFRplot(obj,trialType,startStop,ii,makeNewFig);
         
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
      
      % Return "dataTable" with Spikes & LFP data for this channel
      function dataTable = getDataTable(obj,tPre,tPost)
         %GETDATATABLE Return table with trial Spike & LFP data
         %
         %  dataTable = getDataTable(obj);
         %  dataTable = getDataTable(obj,tPre,tPost);
         %
         % Inputs
         %  obj   - Scalar or array of `solChannel` objects
         %  tPre  - (Optional) Time (sec) prior to alignment event
         %  tPost - (Optional) Time (sec) after alignment event
         %
         % Output
         %  dataTable - Table with 2 variables: Spikes & LFP, where columns
         %                 are time samples and rows are trials.
         
         if nargin < 2
            [tPre,tPost] = solChannel.getDefault('tpre','tpost');
         elseif nargin < 3
            tPost = solChannel.getDefault('tpost');
         end
         
         if ~isscalar(obj)
            dataTable = table.empty;
            for i = 1:numel(obj)
               dataTable = [dataTable; ...
                  getDataTable(obj(i),tPre,tPost)];
            end
            return;
         end
         
         % Return all binned spikes (for all trials) on this channel
         allTrials = cfg.TrialType('All');
         Spikes = getBinnedSpikes(obj,allTrials,tPre,tPost);
         
         % Return all aligned LFP data
         LFP = getAlignedLFP(obj,allTrials);
         
         % Make table for Spikes & LFP data
         dataTable = table(Spikes, LFP);
         dataTable.Properties.Description = ...
            'Table with Spike & LFP data in alignment to stimuli';
         dataTable.Properties.VariableDescriptions = ...
            {'Histogram bin counts of spikes by trial',...
             'Decimated LFP voltage signal (microvolts) during trial'};
          dataTable.Properties.UserData = struct(...
             'type','Data',...
             'tSpike',linspace(tPre,tPost,size(Spikes,2)),...
             'tLFP',linspace(tPre,tPost,size(LFP,2)));
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
      function fs = getfs_d(obj)
         %GETFS_D Return decimated sample rate (for LFP) for this channel
         %
         % fs = getfs_d(obj);
         %
         % Inputs
         %  obj - Scalar or array `solChannel` object
         %
         % Output
         %  fs  - Scalar or array matching `obj`, with values that
         %        correspond to the decimated sample rate for LFP on a
         %        particular `block`
         
         if ~isscalar(obj)
            fs = nan(size(obj));
            for i = 1:numel(obj)
               fs(i) = getfs_d(obj(i));
            end
            return;
         end
         in = load(obj.ds,'fs');
         fs = in.fs;
         obj.fs_d = fs;
      end
      
      % Returns LOWPASS FILTERED (DECIMATED; LFP) data for this channel
      function [data,t] = getLFP(obj,ch,vec)
         %GETLFP Return decimated, lowpass filtered data for this channel
         %
         % [data,t] = getLFP(obj,ch,vec);
         %  
         % Inputs
         %  obj - Scalar or array of `solChannel` objects
         %  ch  - Indexing vector to subset of `obj` if input is array
         %        (default if not specified is to return for all `obj`)
         %  vec - "Mask" vector (default is `inf`, which returns all
         %        samples) in case you want to only return a subset of
         %        samples corresponding to some vector of interest.
         %
         % Output
         %  data - Data matrix where columns are samples and rows
         %           correspond to elements of `obj`
         %  t    - Time vector corresponding to columns of `data`
         
         if nargin < 2
            ch = 1:numel(obj);
         end
         if nargin < 3
            vec = inf;
         end
         if numel(obj) > 1
            for ii = 1:numel(ch)
               if ii == 1
                  [data,t] = getLFP(obj(ch(ii)),ch(ii),vec);
               else
                  data = [data; getLFP(obj(ch(ii)),ch(ii),vec)];
               end
            end
            return;
         end
         
         fs = obj.getfs_d;
         in = load(obj.ds,'data');
         if nargout > 1
            t = (0:(numel(in.data)-1))/fs;
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
      
      % Returns AP, ML, and Depth coordinates for this channel
      function [AP,ML,Depth] = getLocation(obj,name)
         %GETLOCATION Return AP, ML, and Depth coordinates for this channel
         %
         % [AP,ML,Depth] = getLocation(obj);
         % [AP,ML,Depth] = getLocation(objArray,name); 
         %  -> Return array of each coordinate corresponding to subset
         %     matching `name` argument
         %
         % Inputs
         %  obj  - Scalar or array of `solChannel` objects
         %  name - (Optional) Scalar or array of strings to use to match
         %              specific elements from `obj`. If this is used, then
         %              only matching coordinates are returned.
         %
         % Output
         %  AP    - `obj.AP` (anteroposterior distance in mm from Bregma)
         %  ML    - `obj.ML` (anteroposterior distance in mm from Bregma)
         %  Depth - `obj.Depth` (depth from dorsal surface in microns)
         
         if nargin > 1
            AP = nan(size(name));
            ML = nan(size(name));
            Depth = nan(size(name));
            allNames = vertcat(obj.Name);
            for ii = 1:numel(name)
               idx = strcmpi(allNames,name(ii));
               if sum(idx) == 1
                  [AP(ii),ML(ii),Depth(ii)] = getLocation(obj(idx));
               end
            end
            return;
         end
         AP = obj.AP;
         ML = obj.ML;
         Depth = obj.Depth;
      end
      
      % Returns RAW data for this channel (and corresponding sample times)
      function [data,t] = getRaw(obj,ch,vec)
         %GETLFP Return raw data for this channel
         %
         %  data = getRaw(obj)
         %  [data,t] = getRaw(obj,ch,vec);
         %  
         % Inputs
         %  obj - Scalar or array of `solChannel` objects
         %  ch  - Indexing vector to subset of `obj` if input is array
         %        (default if not specified is to return for all `obj`)
         %  vec - "Mask" vector (default is `inf`, which returns all
         %        samples) in case you want to only return a subset of
         %        samples corresponding to some vector of interest.
         %
         % Output
         %  data - Data matrix where columns are samples and rows
         %           correspond to elements of `obj`
         %  t    - Time vector corresponding to columns of `data`
         
         if nargin < 2
            ch = 1:numel(obj);
         end
         if nargin < 3
            vec = inf;
         end
         
         if numel(obj) > 1
            for ii = 1:numel(ch)
               if ii == 1
                  [data,t] = getRaw(obj(ch(ii)),ch(ii),vec);
               else
                  data = [data; getRaw(obj(ch(ii)),ch(ii),vec)]; %#ok<*AGROW>
               end
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
      function [edges,tPre,tPost] = getSpikeBinEdges(obj)
         %GETSPIKEBINEDGES Return spike bin edges used in histogram 
         %
         %  edges = getSpikeBinEdges(obj);
         %  [edges,tPre,tPost] = getSpikeBinEdges(obj);
         %
         % Inputs
         %  obj   - Scalar or array of `solChannel` objects
         %  
         % Output
         %  edges - If `obj` is scalar, then this is a vector of the bin
         %           edge times (sec) used to produce any of the histograms
         %           (e.g. PETH) for `obj`; if `obj` is array, then this is
         %           returned as a cell array, where each element is such a
         %           vector of edge times.
         %  tPre  - Time (sec) of first element of `edges` (convenience)
         %  tPost - Time (sec) of last element of `edges` (convenience)
         
         if ~isscalar(obj)
            edges = cell(size(obj));
            tPre = nan(size(obj));
            tPost = nan(size(obj));
            for i = 1:numel(obj)
               [edges{i},tPre(i),tPost(i)] = getSpikeBinEdges(obj(i));
            end
            return;
         end
         
         if isempty(obj.edges)
            setSpikeBinEdges(obj);
         end
         edges = obj.edges;
         tPre = edges(1);
         tPost = edges(end);

      end
      
      % Return times of ICMS stimuli
      function [ts,stimCh] = getStims(obj,force_overwrite)
         %GETSTIMS Return times of ICMS stimuli as vector of times
         %
         %  ts = getStims(obj);
         %  [ts,stimCh] = getStims(obj,force_overwrite);
         %
         % Inputs
         %  obj             - Scalar or array of `solChannel` objects
         %  force_overwrite - (Optional) Default is false; if true, then
         %                                force the stim data to be
         %                                re-parsed and overwritten.
         %
         % Output
         %  ts              - Vector of `stim` times (ICMS stimuli)
         %  stimCh          - Vector indicating which stimulation channels
         %                       were used (indexing vector).
         
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
      
      % Return times of TRIALS as a vector of times (seconds)
      function ts = getTrials(obj,trialType,edges)
         %GETTRIALS Return times of experimental trials as vector
         %
         %  ts = getTrials(obj);
         %  ts = getTrials(obj,trialType);
         %
         % Inputs
         %  obj             - Scalar or array of `solChannel` objects
         %  trialType       - Use `cfg.TrialType()` to only return a subset
         %                    of trials (default is cfg.TrialType('All');)
         %
         % Output
         %  ts              - Vector of `trial` times (sec)
         %                    * If `obj` is an array, then `ts` is returned
         %                      as a cell array with cell elements matching
         %                      corresponding elements of `obj` input.
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if ~isscalar(obj)
            ts = cell(size(obj));
            if nargin < 3
               for i = 1:numel(obj)
                  ts{i} = getTrials(obj(i),trialType);
               end
            else
               for i = 1:numel(obj)
                  ts{i} = getTrials(obj(i),trialType,edges{i});
               end
            end
            return;
         end
         
         if nargin < 3
            [~,tPre,tPost] = getSpikeBinEdges(obj);
         else
            tPre = edges(1);
            tPost = edges(end);
         end
         
         if trialType >= 100
            ts = obj.Parent.Trials;
         else
            ts = obj.Parent.Trials(ismember(...
               obj.Parent.TrialType,trialType));
         end
         ts((ts + tPre) <= 0) = [];
         ts((ts + tPost) >= obj.Parent.TotalDuration) = [];
      end
      
      % Return times of "triggers" (TRIALS) as a vector of time stamps
      function ts = getTrigs(obj)
         %GETTRIGS Return times of "triggers" (old; pilot data)
         %
         %  ts = getTrigs(obj);
         %
         % Inputs
         %  obj - Scalar or array of `solChannel` objects
         %
         % Output
         %  ts  - Array of timestamps (sec) of "triggers"
         %            * If `obj` is an array, then `ts` is returned
         %              as a cell array with cell elements matching
         %              corresponding elements of `obj` input.
         
         if ~isscalar(obj)
            ts = cell(size(obj));
            for i = 1:numel(obj)
               ts{i} = getTrigs(obj(i));
            end
            return;
         end
         
         if isempty(obj.Parent.Triggers)
            obj.Parent.ParseStimuliTimes;
         end
         ts = obj.Parent.Triggers;
      end
      
      % Returns the full-trial IFR estimate and sample times
      function [data,t] = getIFR(obj,ch,vec)
         %GETIFR Returns full-trial firing rate estimate and sample times
         %
         %  data = getIFR(obj);
         %  [data,t] = getIFR(obj,ch,vec);
         %
         % Inputs
         %  obj - Scalar or array of `solChannel` objects
         %  ch  - Indexing vector to subset of `obj` if input is array
         %        (default if not specified is to return for all `obj`)
         %  vec - "Mask" vector (default is `inf`, which returns all
         %        samples) in case you want to only return a subset of
         %        samples corresponding to some vector of interest.
         %
         % Output
         %  data - Data matrix where columns are samples and rows
         %           correspond to elements of `obj`
         %  t    - Time vector corresponding to columns of `data`
         
         if nargin < 2
            ch = 1:numel(obj);
         end
         if nargin < 3
            vec = inf;
         end
         if numel(obj) > 1
            for ii = 1:numel(ch)
               if ii == 1
                  [data,t] = getIFR(obj(ch(ii)),ch(ii),vec);
               else
                  data = [data; getIFR(obj(ch(ii)),ch(ii),vec)];
               end
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
   end
   
   % Public but hidden `set` methods that probably only in constructor
   methods (Access = public, Hidden = true)
      % Wrapper to iterate and append table array
      function T = appendTables(obj,fcn,varargin)
         %APPENDTABLES Wrapper to iterate and append table array
         %
         %  T = appendTables(obj,fcn,arg1,arg2,...);
         %
         % Inputs
         %  obj - Scalar or array of `solChannel` objects
         %  fcn - Function handle to use for appending table
         %  varargin - Any input arguments required by `fcn`
         %
         % Output
         %  T   - Accumulated table
         
         nCh = numel(obj);
         T = table.empty;
         fprintf(1,'%03d%%\n',0);
         for iCh = 1:nCh
            T = [T; ...
               fcn(obj(iCh),varargin{:})];
            fprintf(1,'\b\b\b\b\b%03d%%\n',round(iCh/nCh*100));
         end
      end
      
      % Set the RAW data file for this channel
      function setRaw(obj,f,id)
         %SETRAW  Set RAW data file for this channel
         %
         %  setRaw(obj);
         %  setRaw(obj,f,id);
         %
         % Inputs
         %  obj - Array or scalar `solChannel` object
         %  f   - Folder tag (e.g. subf = cfg.default('subf'); 
         %                         f = subf.raw;)
         %  id  - File ID tag (e.g. ID = cfg.default('id');
         %                          id = ID.raw;)
         %
         % Output
         %  -- none -- Set the file association for `raw` files on any of
         %              the channels corresponding to elements of `obj`
         
         if nargin < 3
            ID = cfg.default('id');
            id = ID.raw;
         end
         
         if nargin < 2
            subf = cfg.default('subf');
            f = subf.raw;
         end
         
         if ~isscalar(obj)
            for i = 1:numel(obj)
               setRaw(obj(i),f,id);
            end
            return;
         end
         
         obj.raw = fullfile(obj.Parent.folder,[obj.Parent.Name f],...
            sprintf('%s_%s%g_Ch_%03g.mat',obj.Parent.Name,id,...
            obj.port_number,...
            obj.native_order));
      end
      
      % Set the FILTERED data file for this channel
      function setFilt(obj,f,id)
         %SETFILT  Set FILTERED data file for this channel
         %
         %  setFilt(obj);
         %  setFilt(obj,f,id);
         %
         % Inputs
         %  obj - Array or scalar `solChannel` object
         %  f   - Folder tag (e.g. subf = cfg.default('subf'); 
         %                         f = subf.filt;)
         %  id  - File ID tag (e.g. ID = cfg.default('id');
         %                          id = ID.filt;)
         %
         % Output
         %  -- none -- Set the file association for `filt` files on any of
         %              the channels corresponding to elements of `obj`
         
         if nargin < 3
            ID = cfg.default('id');
            id = ID.filt;
         end
         
         if nargin < 2
            subf = cfg.default('subf');
            f = subf.filt;
         end
         
         if ~isscalar(obj)
            for i = 1:numel(obj)
               setFilt(obj(i),f,id);
            end
            return;
         end
         
         obj.filt = fullfile(obj.Parent.folder,[obj.Parent.Name f],...
            sprintf('%s_%s%g_Ch_%03g.mat',obj.Parent.Name,id,...
            obj.port_number,...
            obj.native_order));
      end
      
      % Set the DOWNSAMPLED LFP data file for this channel
      function setDS(obj,f,id)
         %SETDS  Set DOWNSAMPLED-LFP data file for this channel
         %
         %  setDS(obj);
         %  setDS(obj,f,id);
         %
         % Inputs
         %  obj - Array or scalar `solChannel` object
         %  f   - Folder tag (e.g. subf = cfg.default('subf'); 
         %                         f = subf.ds;)
         %  id  - File ID tag (e.g. ID = cfg.default('id');
         %                          id = ID.ds;)
         %
         % Output
         %  -- none -- Set the file association for `ds` files on any of
         %              the channels corresponding to elements of `obj`
         
         if nargin < 3
            ID = cfg.default('id');
            id = ID.ds;
         end
         
         if nargin < 2
            subf = cfg.default('subf');
            f = subf.ds;
         end
         
         if ~isscalar(obj)
            for i = 1:numel(obj)
               setDS(obj(i),f,id);
            end
            return;
         end
         
         obj.ds = fullfile(obj.Parent.folder,[obj.Parent.Name f],...
            sprintf('%s_%s%g_Ch_%03g.mat',obj.Parent.Name,id,...
            obj.port_number,...
            obj.native_order));
      end
      
      % Set the RATE ESTIMATE data file for this channel
      function setRate(obj,f,id,doRateEstimate)
         %SETRATE  Set RATE ESTIMATE data file for this channel
         %
         %  setRate(obj);
         %  setRate(obj,f,id,doRateEstimate);
         %
         % Inputs
         %  obj - Array or scalar `solChannel` object
         %  f   - Folder tag (e.g. subf = cfg.default('subf'); 
         %                         f = subf.rate;)
         %  id  - File ID tag (e.g. ID = cfg.default('id');
         %                          id = ID.rate;)
         %  doRateEstimate - (default: false); if true, re-estimate rate
         %                                      and save to file
         %
         % Output
         %  -- none -- Set the file association for `rate` files on any of
         %              the channels corresponding to elements of `obj`
         
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
         
         if ~isscalar(obj)
            for i = 1:numel(obj)
               setRate(obj(i),f,id,doRateEstimate);
            end
            return;
         end
         
         if isempty(obj.ifr)
            obj.ifr = solChannel.getDefault('rate');
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
            estimateRate(obj);
         end
      end
      
      % Set the SPIKE data file for this channel
      function setSpikes(obj,f,id)
         %SETSPIKES  Set SPIKE data file for this channel
         %
         %  setSpikes(obj);
         %  setSpikes(obj,f,id);
         %
         % Inputs
         %  obj - Array or scalar `solChannel` object
         %  f   - Folder tag (e.g. subf = cfg.default('subf'); 
         %                         f = subf.spikes;)
         %  id  - File ID tag (e.g. ID = cfg.default('id');
         %                          id = ID.spikes;)
         %
         % Output
         %  -- none -- Set file association for `spikes` files on any of
         %              the channels corresponding to elements of `obj`
         
         if nargin < 3
            ID = cfg.default('id');
            id = ID.spikes;
         end
         
         if nargin < 2
            subf = cfg.default('subf');
            f = subf.spikes;
         end
         
         if ~isscalar(obj)
            for i = 1:numel(obj)
               setSpikes(obj(i),f,id);
            end
            return;
         end
         
         obj.spikes = fullfile(obj.Parent.folder,[obj.Parent.Name f],...
            sprintf('%s_%s%g_Ch_%03g.mat',obj.Parent.Name,id,...
            obj.port_number,...
            obj.native_order));
      end
      
      % Set the BIN EDGES used to generate HISTOGRAMS or AVERAGE IFR
      function setSpikeBinEdges(obj,tPre,tPost,binWidth)
         %SETSPIKEBINEDGES Set bin edge times for histograms or IFR plots
         %
         %  setSpikeBinEdges(obj,tPre,tPost,binWidth);
         %
         % Inputs
         %  obj      - Scalar or array of `solChannel` objects
         %  tPre     - Time (sec) prior to event
         %  tPost    - Time (sec) after event
         %  binWidth - Width (sec) of each time bin for counts
         %
         % Output
         %  -- none -- Set the `obj.edges` property for each element of
         %              `obj` array
         
         if nargin < 4
            binWidth = solChannel.getDefault('binwidth');
         end
         
         if nargin < 3
            tPost = solChannel.getDefault('tpost');
         end
         
         if nargin < 2
            tPre = solChannel.getDefault('tpre');
         end
         
         if ~isscalar(obj)
            for ii = 1:numel(obj)
               setSpikeBinEdges(obj(ii),tPre,tPost,binWidth);
            end
            return;
         end
         
         obj.edges = tPre:binWidth:tPost;
      end
      
      % Set the STIM data file for this channel
      function setStims(obj,f,id)
         %SETSTIMS  Set STIM data file for this channel
         %
         %  setStims(obj);
         %  setStims(obj,f,id);
         %
         % Inputs
         %  obj - Array or scalar `solChannel` object
         %  f   - Folder tag (e.g. subf = cfg.default('subf'); 
         %                         f = subf.stim;)
         %  id  - File ID tag (e.g. ID = cfg.default('id');
         %                          id = ID.stim;)
         %
         % Output
         %  -- none -- Set file association for `stim` files on any of
         %              the channels corresponding to elements of `obj`
         
         if nargin < 3
            ID = cfg.default('id');
            id = ID.stim;
         end
         
         subf = cfg.default('subf');
         if nargin < 2
            f = subf.dig;
         end
         
         if ~isscalar(obj)
            for i = 1:numel(obj)
               setStims(obj(i),f,id);
            end
            return;
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
            [areaKey,thetaKey,mlKey,apKey,oKey] = solChannel.getDefault(...
               'areakey','thetakey','mlkey','apkey','orientationkey');
            obj.Area = areaKey.(Probe);
            obj.Hemisphere = cfg.Hem(obj.port_number);
            obj.Probe.Angle = thetaKey.(Probe);
            obj.Probe.ML = mlKey.(Probe);
            obj.Probe.AP = apKey.(Probe);
            obj.Probe.Orientation = oKey.(Probe);
         else % Parse relevant properties from `locData` table
            locData = locData(ismember(locData.Probe,Probe),:);
            parseLayoutInfo(obj,locData.Depth(1));
            obj.Area = string(locData.Area{1});
            obj.Hemisphere = string(locData.Hemisphere{1});
            obj.Probe.Orientation = string(locData.Orientation{1});
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
         theta = obj.Probe.Angle;
         C_ap = obj.Probe.AP;
         C_ml = obj.Probe.ML; 
         
         % For `theta = 0` it would be aligned perfectly to midline. In
         % that case, we consider two different probe orientations:
         % "rostral" (shank 1 would then be the furthest-possible rostral)
         % or "caudal" (shank 1 would then be the furthest-possible caudal)
         switch obj.Probe.Orientation
            case "Rostral"
               obj.AP = C_ap + r*cos(theta); % cos( x) = cos(-x)
               obj.ML = C_ml - r*sin(theta); % sin(-x) = -sin(x)
            case "Caudal"
               obj.AP = C_ap - r*cos(theta); % cos( x) = cos(-x)
               obj.ML = C_ml + r*sin(theta); % sin(-x) = -sin(x)
            otherwise
               error(['SOLENOID:' mfilename ':BadValue'],...
                  ['\n\t->\t<strong>[PARSECHANNELLOCATION]:</strong> ' ...
                   'Unexpected value for `Orientation`: ' ...
                   '<strong>%s</strong>\n\t\t\t\t' ...
                   '(Should be "Rostral" or "Caudal")\n'],...
                   obj.Probe.Orientation);
         end
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
         pInfo = strsplit(obj.Name,'-');
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
   
   % Private static methods
   methods (Static = true, Access = private)
      % Convert `trialData` array struct to table format
      function trialTable = trialData2Table(trialData,tPre,tPost,tTotal)
         %TRIALDATA2TABLE Convert `trialData` array struct to table format
         %
         %  trialTable = solChannel.trialData2Table(trialData,tPre,tPost,tTotal);
         %
         % Inputs
         %  trialData  - Struct array with one element per trial
         %  tPre       - Time prior to alignment (sec)
         %  tPost      - Time after alignment (sec)
         %  tTotal     - Total duration of recording
         %
         % Output
         %  trialTable - Table with one row per trial
         
         [abbrevs,targs] = solChannel.getDefault('all_abbr','all_tgt');
         
         trialTable = struct2table(trialData);
         trialTable(... % Remove invalid trial times
            ((trialTable.Time + tPre) < 0)|...
            ((trialTable.Time + tPost) > tTotal),:) = [];
         trialTable.TrialID = cellfun(@(C)string(C),trialTable.TrialID,'UniformOutput',true);
         trialTable.Type = categorical(trialTable.Type,[1,2,3],["Solenoid", "ICMS", "Solenoid + ICMS"]);
         Targ = cellfun(@(C)string(C),trialTable.Solenoid_Target,'UniformOutput',true);
         trialTable.Solenoid_Target = categorical(Targ,targs);
         Abbrev = cellfun(@(C)string(C),trialTable.Solenoid_Abbrev,'UniformOutput',true);
         trialTable.Solenoid_Abbrev = categorical(Abbrev,abbrevs);
         trialTable.Solenoid_Paw = categorical(trialTable.Solenoid_Paw,["Right"; "Left"]);
         trialTable.Properties.Description = 'Trial metadata table';
         trialTable.Properties.UserData = struct('type','TrialData');
         trialTable.Properties.VariableDescriptions = {...
            'Unique Trial "Key" identifier',...
            'Type of trial (1: ICMS; 2: Solenoid; 3: Sol+ICMS)',...
            'Time of trial (sec) relative to recording onset',...
            'Number of trial relative to start of all trials in recording',...
            'Relative delay (sec) to ICMS pulse onset',...
            'Index to channel(s) delivering intracortical microstimulation (ICMS)',...
            'Relative delay (sec) to extension onset for solenoid',...
            'Relative delay (sec) to retraction onset for solenoid',...
            'Peripheral cutaneous target for solenoid',...
            'Side ("Left" or "Right") targeted by solenoid',...
            'Abbreviation from Tutunculer 2006 convention for target'};
      end
   end
end