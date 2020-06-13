classdef solBlock < handle
%SOLBLOCK  Class for organizing data from an individual recording
%
%   obj = solBlock(); 
%   obj = solBlock(ratObj,folder);
%
% solBlock Properties
%  Name - Recording BLOCK name
%  Parent - Parent solRat handle
%  Children - Array of solChannel child object handles
%  Index - From name convention: "R19-###_2019_MM_DD_[Index]"
%  fs - Amplifier sample rate (Hz)
%  ICMS_Channel_index - Index of channel(s) delivering ICMS (NaN if none)
%  ICMS_Channel_Name - solChannel.Name property of channels delivering ICMS ("None" if no ICMS)
%  ICMS_Onset_Latency - Array of ICMS start times (1 per pulse, per stimulated channel)
%  Location_Table - Table with Probe location data
%  Solenoid_Location - Table of Solenoid location data and metadata
%  Solenoid_Onset_latency - Array of solenoid extension times relative to trial start (sec)
%  Solenoid_Offset_latency - Array of solenoid retraction times relative to trial start (sec)
%  Trials - "Trial" timestamps (new/main experimental data)
%  Triggers - "Trial" triggers (old pilot data)
%  TrialType - Array of cfg.TrialType corresponding to whether each trial delivers ICMS, Solenoid, or Solenoid+ICMS stimuli
%
% solBlock Methods
%  solBlock   - Class constructor
%  makeTables - Return BLOCK table for metadata and data table export

% PROPERTIES
   % Unchangeable properties set on object construction
   properties (GetAccess = public, SetAccess = immutable, Hidden = false)
      Name        % Recording BLOCK name
      Parent      % Parent SOLRAT object handle
      Children    % Array of SOLCHANNEL child object handles
      Index       % From name convention: "R19-###_2019_MM_DD_[Index]"
   end
   
   % Properties with public `get` access, but must be set by class method
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      fs                       % Amplifier sample rate (Hz)
      ICMS_Channel_Index       % Index of channel(s) delivering ICMS
      ICMS_Channel_Name        % Name of ICMS stimulation channel
      ICMS_Onset_Latency       % Array of ICMS start times (1 per pulse, per stimulated channel)
      Location_Table           % Table with location data for each probe (note that reference angle is 0 at horizontal to ref. GRID; positive with clockwise rotation)
      Solenoid_Location        % Table of solenoid location data and metadata
      Solenoid_Onset_Latency   % Array of solenoid extend times (1 per pulse, within a trial)
      Solenoid_Offset_Latency  % Array of solenoid retract times (1 per pulse, within a trial)
      Trials                   % "Trial" timestamps (NEW / CYCLE setup)
      Triggers                 % "Trigger" timestamps (OLD / original setup)
      TrialType                % Categorical array indicating trial type
   end
   
   % Properties with public `get` access, but hidden and must be set by class method
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      folder               % Recording block filepath folder
      sol                  % Solenoid digital record file
      trig                 % "Trigger" digital record file
      iso                  % "Isoflurane" analog record file (pushbutton indicator)
      icms                 % ICMS digital record file
      trial                % "Trial" analog record file
      stim                 % "StimInfo" parsed file
      Layout               % Electrode layout (rows = depth, columns = M/L or A/P shanks)

   end
   
   % Private properties that can only be set/accessed using class methods
   properties (Access = private)
      edges    % Time bin edges for binning histograms relative to alignment
   end

% METHODS
   % Class constructor, overloaded methods, or main interface methods
   methods
      % SOLBLOCK class constructor
      function obj = solBlock(ratObj,folder)
         %SOLBLOCK  Class constructor for `solBlock` "recording" object
         %
         % obj = solBlock();
         % obj = solBlock(solRatObj);
         % obj = solBlock(folder);
         % obj = solBlock(solRatObj,folder);
         %
         % Inputs
         %  solRatObj - (Optional) `solRat` class object for Rat used in
         %              this recording. If given, the constructor will
         %              return an array of `solBlock` objects corresponding
         %              to the number of "Block" folders detected within
         %              the "Rat" folder at the `solRat` level.
         %              -> If no input is provided, a prompt will pop up to
         %                 select the desired BLOCK folder in order to
         %                 return a scalar `solBlock` object from the
         %                 constructor.
         %  folder    - (Optional) char array that is the BLOCK folder path
         %
         % Output
         %  obj       - `solBlock` object representing a single recording,
         %              or an array of such objects representing multiple
         %              recordings from the same rat.
         
         % Set the folder
         if nargin < 1
            clc;
            [obj.folder,flag] = utils.getPathTo('Select BLOCK folder');
            if ~flag
               obj = [];
               return;
            end
            obj.Parent = [];
         elseif isa(ratObj,'solRat') && nargin > 1
            obj.Parent = ratObj;
            obj.folder = folder;
         elseif ischar(ratObj)
            obj.folder = ratObj;
            obj.Parent = [];
         elseif isscalar(ratObj) && isnumeric(ratObj)
            obj = repmat(obj,ratObj,1); % Create empty array of BLOCKS
            return;
         end
         
         % Parse recording name based on BLOCK folder naming
         [obj.Name,obj.Index] = parseName(obj);
         
         % Load configured defaults
         [subf,id,L,fname] = solBlock.getDefault(...
            'subf','id','L','site_location_table');
         
         % Set the electrode LAYOUT for this object
         setLayout(obj,L,fname);
         
         % Set sample rate for this object
         setSampleRate(obj,id);
         
         % Construct child CHANNEL objects
         obj.Children = setChannels(obj,subf,id);
         
         % Get other metadata         
         setMetaNames(obj,subf,id);
         
         % Parse trial times
         setTrials(obj);
         
         % Set ICMS stimuli
         setStims(obj);
         
         % Set the solenoid latencies
         setSolenoidLatencies(obj);
         
         % Parse solenoid location data
         parseSolenoidInfo(obj);
         
         % Parse distance of each child channel to stimulation site
         parseStimDistance(obj);
      end
      
      % Returns **block** data table for convenient export of dataset
      function blockTable = makeTables(obj)
         %MAKETABLES Returns data table elements specific to `solBlock`
         %
         %  blockTable = obj.makeTables;
         %  blockTable = makeTables(objArray);
         %
         %  Inputs
         %     obj - Scalar or Array of `solBlock` objects
         %  
         %  Output
         %     blockTable - Table with the following variables:
         %        * `BlockID`  - Name of recording block
         %        * `TrialID`  - Trial-specific identifier (might be
         %                          replicated for all channels within a
         %                          Block)
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
         %        * `Solenoid_Location` - Location of Solenoid strike on
         %                                   peripheral cutaneous region
         %        * `TrialType`- {'Solenoid','ICMS', or 'Solenoid+ICMS'}
         %        * `Spikes` - Binned spike counts relative to alignment
         %                       for a single channel.
         %        * `LFP`    - LFP time-series relative to alignment for a
         %                       single channel.
         %        * `Notes` - Most-likely empty, but allows manual input of
         %                    notes or maybe a notes struct? Basically
         %                    something that lets you manually add "tags" 
         %                    to the data rows.
         %
         %
         % See also: solBlock.getTrialData, solChannel.makeTables,
         %           solRat.makeTables
      
         % Since it can be an array, iterate/recurse over all the blocks
         if ~isscalar(obj)
             blockTable = table.empty; % Create empty data table to append
             for iBlock = 1:numel(obj)

               blockTable = [blockTable; solBlock.makeTable(obj(iBlock))]; %#ok<AGROW>
             end
             return;
         end
      
         % Need to parse the following variables from Block:
         %  * `TrialID`  - Since "Block" contains list of all trial instances,
         %                 each of those instances should get an associated
         %                 'TrialID' and that can be passed to the
         %                 `makeTables` method of `solChannel` so that it is
         %                 added to each trial of individual channel data
         %                 properly.
         %  * `TrialType` - Same as `TrialID`
         %  * `BlockID`  - obj.Name
         %  * Generally, we will get all information about the electrodes as a
         %     single data structure that is obtained with every recording.
         %     However, to be manipulated easily, that metadata needs to be
         %     associated at an individual Channel level with each channel
         %     properly. So we should pass that `info` struct, which contains
         %     things like `Depth` and `XLoc` and `Area` etc. to the method of
         %     `solChannel` in order to properly associate them. Ideally, that
         %     `info` struct is already associated with the `solChannel`
         %     object as one of its properties from the constructor, when such
         %     data is parsed generally and added to the properties at the
         %     relevant level. 
         %
         %   * The rest of the table comes from
         %     ```
         %        trialData = getTrialData(obj); % Not yet written
         %        channelTable = makeTables(obj.Children,trialData);
         %     ```
         %
         %  Strategy -- 
         %     1) Create `trialTable` in this method using data from Block
         %           * Mainly, we can get `TrialID` `TrialTime` and
         %              `TrialType` (the three main fields that should be
         %              incorporated to the `trialData` struct array returned
         %              by `getTrialData(obj)`); those will have to be
         %              replicated properly either within
         %              `makeTables(obj.Children);` or at this level so that
         %              the number of rows match
         %     2) Create `channelTable` using syntax above
         %     3) Replicate `trialTable` to same number of rows as 
         %           `channelTable`
         %     4) Concatenate the two tables (horizontally) to create
         %        `blockTable`

         % Get struct array that contains metadata such as stimulus type 
         % and onset, as well as which channel was stimulate, for each 
         % trial. This array can then be replicated so that there is an 
         % equivalent array for each "child" table (channel table) that is 
         % passed back:
         trialData = getTrialData(obj);

         % % Return the `channelTable` for all child 'Channel' objects % %
         % Note 1: `makeTables` for `solChannel` will essentially
         %          replicate `trialData` array struct, and includes the 
         %          necessary trial-relevant information in the output 
         %          `channelTable`
         % Note 2:  All relative depth/spatial information about the
         %          `solChannel` object should already be associated with
         %          that object at this point, from being set in the
         %          constructor or calls to hidden public methods of
         %          `solBlock` prior to execution of `makeTables`
         
         channelTable = makeTables(obj.Children,trialData); 
         nRows = size(channelTable,1);

         % Note that `solTable` contains `BlockID` column already
         solTable = obj.Solenoid_Location;
         solTable = repmat(solTable,nRows,1);
         
         % Concatenate Block-level info with Channel-level info for output
         blockTable = [solTable, channelTable];
      
      end %%%% End of makeTables%%%%
      
   end
   
   % Public methods
   methods (Access = public)
      % Plot the aligned LFP for each channel
      function fig = avgLFPplot(obj,trialType,tPre,tPost,subset)
         %AVGLFPPLOT Plot the aligned LFP for each channel
         %
         % fig = avgLFPplot(obj,trialType,tPre,tPost,subset);
         %
         % Inputs
         %  obj - scalar or array `solBlock` object
         %  trialType - Enumerated trial type that we want to select for
         %              plots
         %  tPre      - "Pre" time, relative to alignment event
         %  tPost     - "Post" time, relative to alignment event
         %  subset    - (Optional) if obj is array, then this should be
         %              cell array of same size. If not provided, plot all
         %              trials for a given `solBlock` obj. If given, each
         %              cell array element should be an indexing array that
         %              indexes which trials to include from the restricted
         %              set of trials set by `trialType` argument.
         %
         % Output
         %  fig      - Figure handle or array of `matlab.graphics.figure`
         %              handles corresponding to generated figures, one for
         %              each element of `obj`
         
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
            fig = gobjects(size(obj));
            for i = 1:numel(obj)
               if nargin < 5
                  fig(i) = avgLFPplot(obj(i),trialType,tPre,tPost);
               else
                  if ~iscell(subset)
                     subset = repmat({subset},size(obj));
                  end
                  fig(i) = avgLFPplot(obj(i),trialType,tPre,tPost,subset{i});
               end
            end
            return;
         elseif iscell(subset)
            subset = subset{:};
         end
         
         if nargin < 5
            subset = 1:numel(obj.Children);
         else
            subset = reshape(subset,1,numel(subset));
         end
         
         edgeVec = [tPre,tPost];        
         fig = avgLFPplot(obj.Children(subset),trialType,edgeVec);
         
      end
      
      % Plot the peri-event time histogram for each channel as batch run
      function batchPETH(obj,trialType,tPre,tPost,binWidth,subset)
         %BATCHPETH Plot the peri-event time histogram for each channel
         %
         % fig = batchPETH(obj,trialType,tPre,tPost,binWidth,subset);
         %
         % Inputs
         %  obj - scalar or array `solBlock` object
         %  trialType - Enumerated trial type to select for PETH plots
         %  tPre      - "Pre" time, relative to alignment event
         %  tPost     - "Post" time, relative to alignment event
         %  binWidth  - Bin size (seconds) for histogram bars
         %  subset    - (Optional) if obj is array, then this should be
         %              cell array of same size. If not provided, plot all
         %              trials for a given `solBlock` obj. If given, each
         %              cell array element should be an indexing array that
         %              indexes which trials to include from the restricted
         %              set of trials set by `trialType` argument.
         %
         % Output
         %  fig      - Figure handle or array of `matlab.graphics.figure`
         %              handles corresponding to generated figures, one for
         %              each element of `obj`
         %
         % See also: solBlock.PETH, solChannel.PETH, solBlock.probePETH
         
         if nargin < 5
            binWidth = solBlock.getDefault('binwidth');
         end
         
         if nargin < 4
            tPost = solBlock.getDefault('tpost');
         end
         
         if nargin < 3
            tPre = solBlock.getDefault('tpre');
         end
         
         if nargin < 2
            trialType = solBlock.getDefault('All');
         end
         
         % Only use `subset` for each element of obj, since it may be
         % different for each (depending on number of child channels)
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               if nargin < 6
                  batchPETH(obj(ii),trialType,tPre,tPost,binWidth);
               else
                  batchPETH(obj(ii),trialType,tPre,tPost,binWidth,subset);
               end
            end
            return;
         end
         
         if nargin < 6
            subset = 1:numel(obj.Children);
         end
         
         edgeVec = tPre:binWidth:tPost;

         [subf,id] = solBlock.getDefault('subf','id');
         
         outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.peth);
         if exist(outpath,'dir')==0
            mkdir(outpath);
         end
         
         for ii = subset
            f = PETH(obj.Children(ii),edgeVec,trialType,ii);
            
            savefig(f,fullfile(outpath,[obj.Name '_' obj.Children(ii).Name ...
               char(trialType) '_' id.peth '.fig']));
            saveas(f,fullfile(outpath,[obj.Name '_' obj.Children(ii).Name ...
               char(trialType) '_' id.peth '.png']));
            
            delete(f);
            
         end
      end
      
      % Returns the closest timestamp of a trial ONSET (seconds)
      function t = getClosestTrialOnset(obj,tVec)
         %GETCLOSESTTRIALONSET Returns the closest timestamp of trial start
         %
         % t = getClosestTrialOnset(obj,tVec);
         %
         % Inputs
         %  obj  - SCALAR `solBlock` object
         %  tVec - Vector of candidate times
         %
         % Output
         %  t    - Actual time of closest trial onset
         
         if ~isscalar(obj)
            error(['SOLENOID:' mfilename ':BadInputSize'],...
               ['\n\t->\t<strong>[GETCLOSESTTRIALONSET]:</strong> ' ...
                'This method only accepts a scalar `obj` input\n']);
         end
         ts = obj.getTrials;
         [~,idx] = min(abs(ts - tVec(1)));
         t = ts(idx);
      end
      
      % Get the normalized position for current figure placement 
      function pos = getFigPos(obj,ii,varargin)
         %GETFIGPOS Return normalized position of current figure
         %
         % pos = getFigPos(obj);
         % pos = getFigPos(obj,ii);
         % pos = getFigPos(obj,ii,'Position',pos,'Scale',scl);
         %
         % Inputs
         %  obj - Scalar `solBlock` object
         %        -> If given as an array, throws warning and only uses
         %           first element to return `pos`
         %  ii  - Index (scalar integer) corresponding to this figure
         %        -> Default: random integer based on number of
         %                    `obj.Children`
         %  varargin - Optional <'Name',value> pairs
         %        + 'Position': the original position, to be scaled based
         %                       on indexing relative to number of child
         %                       objects
         %        + 'Scale'   : the maximum (normalized) factor to add to
         %                       both pos(1) and pos(2)
         %
         % Output
         %  pos   - Updated figure `Position` (normalized coordinates)
         %     --> Use this to make a cascaded tile of figures across the 
         %         screen when multiple figures will be generated by a 
         %         method, so that they don't just all stack one on top of
         %         the other.
         
         if ~isscalar(obj)
            warning(['SOLENOID:' mfilename ':BadInputSize'],...
               ['\n\t->\t<strong>[GETFIGPOS]:</strong> ' ...
                'This method should only accept scalar inputs.\n' ...
                '\t\t\t\t(Using first element only)\n']);
             obj = obj(1);
         end
         
         N = numel(obj.Children);
         if nargin < 2
            ii = randi(N,1,1);
         end
         
         p = struct;
         [p.Position,p.Scale] = solBlock.getDefault('figpos','figscl');
         
         fn = fieldnames(p);
         for iV = 1:2:numel(varargin)
            idx = strcmpi(fn,varargin{iV});
            if sum(idx)==1
               p.(fn{idx}) = varargin{iV+1};
            end
         end
         
         k = ii / N; % Scale factor
         pos(1) = p.Position(1) + p.Scale * k;
         pos(2) = p.Position(2) + p.Scale * k;
      end
      
      % Get ICMS times (for new CYCLE setup)
      function ts = getICMS(obj)
         %GETICMS Return array of ICMS pulse onset times
         %
         % ts = getICMS(obj);
         %
         % Inputs
         %  obj              - Scalar or array of `solBlock` objects
         %
         % Output
         %  ts               - Vector of timestamps (seconds) of ICMS pulse
         %                       onsets. If `obj` is an array, then this is
         %                       a cell array, where each element contains
         %                       such a vector that matches the
         %                       corresponding element of `obj`
         
         % Handle object array input
         if numel(obj) > 1
            ts = cell(numel(obj),1);
            for i = 1:numel(obj)
               ts{i} = getICMS(obj(i));
            end
            return;
         end
         
         if exist(obj.icms,'file')==0
            fprintf(1,'No file: %s\n',obj.icms);
            ts = [];
            return;
         end
         
         in = load(obj.icms,'data');
         if sum(in.data > 0) == 0
            ts = [];
            return;
         end
         
         % Find onset of "HIGH" times
         data = find(in.data > 0);
         
         % Convert sample indices to times (SECONDS)
         ts = data([true, diff(data) > 1]) ./ obj.fs;
         
         % Simplify parsing "incomplete" trials
         if numel(ts) > 1
            ts = ts(1:(end-1)); 
         end
         
      end
      
      % Get TRIAL times (for new CYCLE setup)
      function ts = getTrials(obj,updateTrialsProp)
         %GETTRIALS Return array of trial onset times
         %
         % ts = getTrials(obj);
         % ts = getTrials(obj,updateTrialsProp);
         %
         % Inputs
         %  obj              - Scalar or array of `solBlock` objects
         %  updateTrialsProp - Default is false; set true to force the
         %                     `Trials` property to be updated with values
         %                     returned in `ts`
         %
         % Output
         %  ts               - Vector of timestamps (seconds) of trial
         %                       onsets. If `obj` is an array, then this is
         %                       a cell array, where each element contains
         %                       such a vector that matches the
         %                       corresponding element of `obj`
         
         if nargin < 2
            updateTrialsProp = false;
         end
         
         % Handle object array input
         if numel(obj) > 1
            ts = cell(numel(obj),1);
            for i = 1:numel(obj)
               ts{i} = getTrigs(obj(i),updateTrialsProp);
            end
            return;
         end
         
         if exist(obj.trial,'file')==0
            successful_parse = obj.parseTrials;
            if ~successful_parse
               ts = [];
               return;
            end
         end
         
         in = load(obj.trial,'data');
         thresh = cfg.default('analog_thresh');
         if sum(in.data > thresh) == 0
            ts = [];
            return;
         end
         
         % Find onset of "HIGH" times
         data = find(in.data > thresh);
         
         % Convert sample indices to times (SECONDS)
         ts = data([true, diff(data) > 1]) ./ obj.fs;
         
         % Simplify parsing "incomplete" trials
         if numel(ts) > 1
            ts = ts(1:(end-1)); 
         end
         
         if updateTrialsProp
            obj.Trials = ts;
         end
         
      end
      
      % Get "trigger" times (for old digIO setup)
      function ts = getTrigs(obj)
         %GETTRIGS Returns "trigger" times (from old `digIO` setup)
         %
         % ts = getTrigs(obj);
         %
         % Inputs
         %  obj - Scalar or array of `solBlock` objects
         %  
         % Output
         %  ts  - Array of timestamps of "trig" LOW to HIGH times. If
         %        `obj` is an array, then returns a cell array the same
         %        size as `obj`, where each cell element contains an array
         %        of such timestamps (seconds)
         
         if ~isscalar(obj)
            ts = cell(size(obj));
            for i = 1:numel(obj)
               ts{i} = getTrigs(obj(i));
            end
            return;
         end
         
         in = load(obj.trig,'data');
         if sum(in.data) == 0
            ts = [];
            return;
         end
         
         data = find(in.data > 0);
         ts = data([true, diff(data) > 1]) ./ obj.fs;
         obj.Triggers = ts;
      end
      
      % Return array of solenoid extension onset times
      function ts = getSolOnset(obj,db)
         %GETSOLONSET Returns times when solenoid goes from LOW to HIGH
         %
         % ts = getSolOnset(obj);
         % ts = getSolOnset(obj,db);
         %
         % Inputs
         %  obj - Scalar or array of `solBlock` objects
         %  db  - Debounce threshold (samples; default: 1 [no debounce])
         %  
         % Output
         %  ts  - Array of timestamps of times when solenoid extends. If
         %        `obj` is an array, then returns a cell array the same
         %        size as `obj`, where each cell element contains an array
         %        of such timestamps (seconds)
         
         if nargin < 2
            db = 1; % Default of no debounce
         end
         
         if ~isscalar(obj)
            ts = cell(size(obj));
            for i = 1:numel(obj)
               ts{i} = getSolOnset(obj(i),db);
            end
            return;
         end
         
         in = load(obj.sol,'data');
         if sum(in.data) == 0
            ts = [];
            return;
         end
         
         data = find(in.data > 0);
         ts = data([true, diff(data) > db]) ./ obj.fs;
      end
      
      % Return array of solenoid retraction onset times
      function ts = getSolOffset(obj,db)
         %GETSOLOFFSET Returns times when solenoid goes from HIGH to LOW
         %
         % ts = getSolOffset(obj);
         % ts = getSolOffset(obj,db);
         %
         % Inputs
         %  obj - Scalar or array of `solBlock` objects
         %  db  - Debounce threshold (samples; default: 1 [no debounce])
         %  
         % Output
         %  ts  - Array of timestamps of times when solenoid retracts. If
         %        `obj` is an array, then returns a cell array the same
         %        size as `obj`, where each cell element contains an array
         %        of such timestamps (seconds)
         
         if nargin < 2
            db = 1; % Default of no debounce
         end
         
         if ~isscalar(obj)
            ts = cell(size(obj));
            for i = 1:numel(obj)
               ts{i} = getSolOffset(obj(i),db);
            end
            return;
         end
         
         in = load(obj.sol,'data');
         if sum(in.data) == 0
            ts = [];
            return;
         end
         
         data = find(in.data > 0);
         ts = data([diff(data) > db, true]) ./ obj.fs;
      end
      
      % Return the spike bin (histogram) edge times
      function edges = getSpikeBinEdges(obj)
         %GETSPIKEBINEDGES Return spike bin (histogram) edge times
         %
         % edges = getSpikeBinEdges(obj);
         %
         % Inputs
         %  obj   - Scalar or array of `solBlock` objects
         %  
         % Output
         %  edges - Vector of bin edge times for the spike histogram, which
         %          contains (# bins + 1) elements. If `obj` is an array,
         %          then returns a cell array of such vectors.
         
         if ~isscalar(obj)
            edges = cell(numel(obj),1);
            for ii = 1:numel(obj)
               edges{ii} = getSpikeBinEdges(obj(ii));
            end
            return;
         end
         
         if isempty(obj.edges)
            setSpikeBinEdges(obj);
         end
         edges = obj.edges;
      end
      
      % Return data related to each trial
      function trialData = getTrialData(obj)
         %GETTRIALDATA Get data that is associated with each trial
         %
         % trialData = getTrialData(obj);
         %
         % Inputs 
         %  obj       - Scalar or array of `solBlock` objects
         %
         % Output
         %  trialData - Struct array where each element corresponds to a
         %                 single trial. If `obj` is passed as an array,
         %                 then these trials correspond to all trials from
         %                 the corresponding blocks.
         %                 Each array element contains the following fields
         %                    * 'ID'   : "key" that is unique to trial
         %                    * 'Type' : indicator of ICMS, Solenoid, or
         %                                ICMS+Solenoid combination
         %                    * 'Time' : Time of trial (relative to start
         %                                of recording; seconds)
         %                    * 'Number' : Trial number within recording
         %                                   block (starts with 1 for first
         %                                   trial in the block, etc.)
         %                    * 'ICMS_Onset' : Onset time relative to start
         %                                      of trial for (each) ICMS
         %                                      pulse. Typically only one
         %                                      pulse but can be an array
         %                                      of onset times. If no ICMS,
         %                                      then this value is `inf`
         %                    * 'ICMS_Channel' : Array containing channel
         %                                         indices for each
         %                                         stimulated channel. If
         %                                         no ICMS on this trial,
         %                                         then the value is empty.
         %                    * 'Solenoid_Onset' : Onset time for solenoid
         %                                         strike relative to start
         %                                         of trial (sec). If no
         %                                         solenoid strike, this
         %                                         value is `inf`
         %                    * 'Solenoid_Offset' : Time of retraction of
         %                                          solenoid, relative to
         %                                          start of trial (sec).
         %                                          If no solenoid strike,
         %                                          this is `inf`
         %
         % See also: solBlock.makeTables, solChannel.makeTables,
         %           solRat.makeTables
         
         % % Iterate on array % %
         if ~isscalar(obj)
            n = numel(obj);
            trialData = cfg.default('init_trial_data');
            for i = 1:n
               trialData = [trialData; getTrialData(obj(i))]; %#ok<AGROW>
            end
            return;
         end
         
         % % Initialize `trialData` struct array % %
         trialData = cfg.default('init_trial_data');
         nTrial = numel(obj.Trials);
         trialData = repmat(trialData,nTrial,1);
         
         % % Use `deal` to assign struct array elements from properties % %
         time = num2cell(obj.Trials);
         [trialData.Time] = deal(time{:});
         ID = utils.makeKey(nTrial,'unique',sprintf('B%02d_',obj.Index));
         [trialData.ID] = deal(ID{:});
         trialtype = num2cell(obj.TrialType);
         [trialData.Type] = deal(trialtype{:});
         trialNumber = num2cell((1:nTrial)');
         [trialData.Number] = deal(trialNumber{:});
         
         % % % Get ICMS information (for each trial) % % %
         % ICMS for TrialType == 2 (ICMS) or TrialType == 3 (SolICMS)
         stimTrials = (obj.TrialType == 2) | (obj.TrialType == 3);
         
         % % Onset % %
         stimOnsetLatency = {obj.ICMS_Onset_Latency};
         lat_empty = {inf(size(obj.ICMS_Onset_Latency))};
         lat = cell(nTrial,1);
         lat(stimTrials) = stimOnsetLatency;
         lat(~stimTrials) = lat_empty;
         [trialData.ICMS_Onset] = deal(lat{:});
         
         % % Stim Channel % %
         stimChannelIndex = {obj.ICMS_Channel_Index};
         ch = cell(nTrial,1);
         ch(stimTrials) = stimChannelIndex;
         [trialData.ICMS_Channel] = deal(ch{:});
         
         % % % Get Solenoid information (for each trial) % % %
         % Solenoid: TrialType == 1 (Solenoid) or TrialType == 3 (SolICMS)
         solTrials = (obj.TrialType == 1) | (obj.TrialType == 3);
         nSolPulse = numel(obj.Solenoid_Onset_Latency);
         
         % % Onset % %
         on = inf(nTrial,nSolPulse);
         on(solTrials,:) = obj.Solenoid_Onset_Latency;
         on = mat2cell(on,ones(1,nTrial),nSolPulse);
         [trialData.Solenoid_Onset] = deal(on{:});
         
         % % Offset % %
         off = inf(nTrial,nSolPulse);
         off(solTrials,:) = obj.Solenoid_Offset_Latency;
         off = mat2cell(off,ones(1,nTrial),nSolPulse);
         [trialData.Solenoid_Offset] = deal(off{:});
         
         % % General Block-related Solenoid info % %
         solTable = obj.Solenoid_Location;
         [trialData.Solenoid_Target] = deal(string(solTable.Location{1}));
         [trialData.Solenoid_Paw] = deal(string(solTable.Paw{1}));
         [trialData.Solenoid_Abbrev] = deal(string(solTable.TAG{1}));
         [trialData.Notes] = deal(string(solTable.Notes{1}));
      end
      
      % Plot organized subplots for PETH of each channel
      function probePETH(obj,trialType,tPre,tPost,binWidth,batchRun)
         %PROBEPETH Plot the PETH with subplots organized by channel layout
         %
         % fig = probePETH(obj,trialType,tPre,tPost,binWidth,batchRun);
         %
         % Inputs
         %  obj - scalar or array `solBlock` object
         %  trialType - Enumerated trial type to select for PETH plots
         %  tPre      - "Pre" time, relative to alignment event
         %  tPost     - "Post" time, relative to alignment event
         %  binWidth  - Bin size (seconds) for histogram bars
         %  batchRun  - (Optional) default is false. Set true to generate
         %                 figures as a batch run in which figures are
         %                 generated, saved to a file, and deleted (saves
         %                 on graphics memory when running a loop).
         %
         % Output
         %  fig      - Figure handle or array of `matlab.graphics.figure`
         %              handles corresponding to generated figures, one for
         %              each element of `obj`
         %
         % See also: solBlock.PETH, solBlock.batchPETH, solChannel.PETH
         
         if nargin < 6
            batchRun = false;
         end
         
         if nargin < 5
            binWidth = solBlock.getDefault('binwidth');
         end
         
         if nargin < 4
            tPost = solBlock.getDefault('tpost');
         end
         
         if nargin < 3
            tPre = solBlock.getDefault('tpre');
         end
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               probePETH(obj(ii),trialType,tPre,tPost,binWidth,batchRun);
            end
            return;
         end
         
         
         nTrial = sum(obj.TrialType == trialType);
         
         edgeVec = tPre:binWidth:tPost;   
         
         % Get label whether it's RFA or S1
         if isempty(obj.Location_Table)
            [a_loc,b_loc] = solBlock.getDefault(...
               'probe_a_loc','probe_b_loc');
         else
            locs = obj.Location_Table;
            a_loc = locs.Area{ismember(locs.Probe,'A')};
            b_loc = locs.Area{ismember(locs.Probe,'B')};
         end
         
         if isempty(obj.Layout) % If no Layout, use default from config
            setLayout(obj);
         end
         % First, make figure for Probe-A
         aFig = figure(...
            'Name',sprintf('%s - %s PETH (%s trials)',...
            obj.Name,a_loc,char(trialType)),...
            'Units','Normalized',...
            'Position',[0.1 0.1 0.4 0.8],...
            'Color','w');           
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Left);
         for ii = 1:numel(c)
            idx = find(contains({c.Name},obj.Layout{ii}),1,'first');
            ax = subplot(round(numel(obj.Layout)/4),4,ii);
            PETH(c(idx),edgeVec,trialType,1,ax);
         end
         suptitle(sprintf('%s (n = %g)',a_loc,nTrial));
         % Next, make figure for Probe-B
         bFig = figure(...
            'Name',sprintf('%s - %s PETH (%s trials)',...
            obj.Name,b_loc,char(trialType)),...
            'Units','Normalized',...
            'Position',[0.5 0.1 0.4 0.8],...
            'Color','w');
         
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Right);
         for ii = 1:numel(c)
            idx = find(contains({c.Name},obj.Layout{ii}),1,'first');
            subplot(round(numel(obj.Layout)/4),4,ii);
            PETH(c(idx),edgeVec,trialType,1,false);
         end
         suptitle(sprintf('%s (n = %g)',b_loc,nTrial));
         
         if batchRun
            [subf,id] = solBlock.getDefault('subf','id');            
            outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.probeplots);
            if exist(outpath,'dir')==0
               mkdir(outpath);
            end
            
            savefig(aFig,fullfile(outpath,[obj.Name id.probepeth '_' char(trialType) '-A.fig']));
            savefig(bFig,fullfile(outpath,[obj.Name id.probepeth '_' char(trialType) '-B.fig']));
            saveas(aFig,fullfile(outpath,[obj.Name id.probepeth '_' char(trialType) '-A.png']));
            saveas(bFig,fullfile(outpath,[obj.Name id.probepeth '_' char(trialType) '-B.png']));
            delete(aFig);
            delete(bFig);
         end
         
      end
      
      % Plot the peri-event time histogram (PETH)
      function fig = PETH(obj,trialType,tPre,tPost,binWidth,subset)
         %PETH Plot the peri-event time histogram for each channel
         %
         % fig = PETH(obj,trialType,tPre,tPost,binWidth,subset);
         %
         % Inputs
         %  obj - scalar or array `solBlock` object
         %  trialType - Enumerated trial type to select for PETH plots
         %  tPre      - "Pre" time, relative to alignment event
         %  tPost     - "Post" time, relative to alignment event
         %  binWidth  - Bin size (seconds) for histogram bars
         %  subset    - (Optional) if obj is array, then this should be
         %              cell array of same size. If not provided, plot all
         %              trials for a given `solBlock` obj. If given, each
         %              cell array element should be an indexing array that
         %              indexes which trials to include from the restricted
         %              set of trials set by `trialType` argument.
         %
         % Output
         %  fig      - Figure handle or array of `matlab.graphics.figure`
         %              handles corresponding to generated figures, one for
         %              each element of `obj`
         %
         % See also: solBlock.batchPETH, solBlock.probePETH
         
         if nargin < 6
            subset = 1:numel(obj.Children);
         else
            subset = reshape(subset,1,numel(subset));
         end
         
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

         edgeVec = tPre:binWidth:tPost;         
         fig = PETH(obj.Children(subset),edgeVec,trialType);
      end
      
      % Plot spike raster for each channel of this recording
      function fig = plotRaster(obj,trialType,tPre,tPost,batch,binWidth)
         %PLOTRASTER Plot spike raster for each channel of this recording
         %
         % fig = plotRaster(obj);
         % fig = plotRaster(obj,trialType,tPre,tPost,batch,binWidth);
         %
         % Inputs
         %  obj       - scalar or array `solBlock` object
         %  trialType - (Optional) Enumerated trial type that we want to 
         %              select for plots
         %  tPre      - (Optional) "Pre" time, relative to alignment event
         %  tPost     - (Optional) "Post" time, relative to alignment event
         %  batch     - (Optional) Default is false. Set true to indicate
         %                 batch run (save/delete each figure)
         %  binWidth  - (Optional) Default is false. Set true to save and
         %                 delete each figure after it is generated.
         %
         % Output
         %  fig      - Figure handle or array of `matlab.graphics.figure`
         %              handles corresponding to generated figures, one for
         %              each element of `obj`
         
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if nargin < 3
            tPre = solBlock.getDefault('tpre');
         end
         
         if nargin < 4
            tPost = solBlock.getDefault('tpost');
         end
         
         if nargin < 5
            batch = false;
         end
         
         if nargin >= 6
            setSpikeBinEdges(obj,tPre,tPost,binWidth);
         end
         
          if ~isscalar(obj)
            fig = gobjects(size(obj));
            for ii = 1:numel(obj)
               fig(ii) = plotRaster(obj(ii),trialType,tPre,tPost,batch);
            end
            return;
         end
         
         fig = plotRaster(obj.Children,trialType,tPre,tPost,batch);
         
      end
      
      % Plot the LFP coherence for each channel
      function probeLFPcoherence(obj,trialType,tPre,tPost)
         %PROBELFPCOHERENCE Plot LFP coherence for each channel
         %
         % probeLFPcoherence(obj,trialType,tPre,tPost);
         %
         % Inputs
         %  obj       - scalar or array `solBlock` object
         %  trialType - (Optional) Enumerated trial type that we want to 
         %              select for plots
         %  tPre      - (Optional) "Pre" time, relative to alignment event
         %  tPost     - (Optional) "Post" time, relative to alignment event
         %
         % Output
         %  fig      - Figure handle or array of `matlab.graphics.figure`
         %              handles corresponding to generated figures, one for
         %              each element of `obj`
         
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
            for ii = 1:numel(obj)
               probeLFPcoherence(obj(ii),trialType,tPre,tPost);
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
         
         
         if isempty(obj.Trials)
            fprintf(1,'Trial times not yet parsed for %s.\n',obj.Name,obj.Name);
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
         if numel(c) == 0
            fprintf(1,'No LEFT probe for %s.\n',obj.Name);
            return;
         end
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
%             savefig(fig,fullfile(outpath,[obj.Name id.lfpcoh '-' X.Name '_' char(trialType) '-L.fig']));
%             saveas(fig,fullfile(outpath,[obj.Name id.lfpcoh '-' X.Name '_' char(trialType) '-L.png']));
%             delete(fig);
         end
         x = x ./ numel(c);
         
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Right);
         if numel(c) == 0
            fprintf(1,'No RIGHT probe for %s.\n',obj.Name);
            return;
         end
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
%             savefig(fig,fullfile(outpath,[obj.Name id.lfpcoh '-' X.Name '_' char(trialType) '-R.fig']));
%             saveas(fig,fullfile(outpath,[obj.Name id.lfpcoh '-' X.Name '_' char(trialType) '-R.png']));
%             delete(fig);
         end
         y = y ./ numel(c);
         
         fig = figure(...
            'Name',sprintf('%s Interhemispheric LFP Coherence (%s)',...
               obj.Name,char(trialType)),...
            'Units','Normalized',...
            'Position',[0.1 0.1 0.8 0.8],...
            'Color','w');
         
         wcoherence(x,y,fs,'PhaseDisplayThreshold',0.8); %#ok<*PROPLC>
         xl = str2double(get(gca,'XTickLabel'));
         xl = xl + min(t)*1e3;
         set(gca,'XTickLabel',cellstr(num2str(xl)));

         title('Left-Right Hemisphere LFP Coherence',...
            'FontName','Arial','Color','k','FontSize',16);
         savefig(fig,fullfile(outpath,[obj.Name id.lfpcoh '_' char(trialType) '.fig']));
         saveas(fig,fullfile(outpath,[obj.Name id.lfpcoh '_' char(trialType) '.png']));
         delete(fig);

      end
      
      % Plot the mean aligned LFP for each channel
      function probeAvgLFPplot(obj,trialType,tPre,tPost,batchRun)
         %PROBEAVGLFPPLOT Plot mean aligned LFP for each channel
         %
         % probeAvgLFPplot(obj,trialType,tPre,tPost,batchRun);
         %
         % Inputs
         %  obj       - scalar or array `solBlock` object
         %  trialType - (Optional) Enumerated trial type that we want to 
         %              select for plots
         %  tPre      - (Optional) "Pre" time, relative to alignment event
         %  tPost     - (Optional) "Post" time, relative to alignment event
         %  batchRun  - (Optional) Default is false. Set true to save and
         %                 delete each figure after it is generated.
         %
         % Output
         %  fig      - Figure handle or array of `matlab.graphics.figure`
         %              handles corresponding to generated figures, one for
         %              each element of `obj`
         
         if nargin < 5
            batchRun = false;
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
            for ii = 1:numel(obj)
               probeAvgLFPplot(obj(ii),trialType,tPre,tPost,batchRun);
            end
            return;
         end
         
         nTrial = sum(cfg.TrialType(obj.TrialType) == trialType);
         edgeVec = [tPre,tPost];   
         [a_loc,b_loc] = solBlock.getDefault('probe_a_loc','probe_b_loc');
         
         aFig = figure('Name',sprintf('%s - %s Average LFP (%s trials)',...
            obj.Name,a_loc,char(trialType)),...
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
            avgLFPplot(c(idx),trialType,edgeVec,1,false);
         end
         suptitle(sprintf('%s (n = %g)',a_loc,nTrial));
         
         bFig = figure('Name',sprintf('%s - %s Average LFP (%s trials)',...
            obj.Name,b_loc,char(trialType)),...
            'Units','Normalized',...
            'Position',[0.5 0.1 0.4 0.8],...
            'Color','w');
         
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Right);
         for ii = 1:numel(c)
            idx = find(contains({c.Name},obj.Layout{ii}),1,'first');
            subplot(round(numel(obj.Layout)/4),4,ii);
            avgLFPplot(c(idx),trialType,edgeVec,1,false);
         end
         suptitle(sprintf('%s (n = %g)',b_loc,nTrial));
         
         if batchRun
            subf = cfg.default('subf');
            id = cfg.default('id');
            
            outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.probeplots);
            if exist(outpath,'dir')==0
               mkdir(outpath);
            end
            
            savefig(aFig,fullfile(outpath,[obj.Name id.probeavglfp '_' char(trialType) '-A.fig']));
            savefig(bFig,fullfile(outpath,[obj.Name id.probeavglfp '_' char(trialType) '-B.fig']));
            saveas(aFig,fullfile(outpath,[obj.Name id.probeavglfp '_' char(trialType) '-A.png']));
            saveas(bFig,fullfile(outpath,[obj.Name id.probeavglfp '_' char(trialType) '-B.png']));
            delete(aFig);
            delete(bFig);
         end
         
      end
      
      % Plot the mean aligned IFR for each channel. 
      function probeAvgIFRplot(obj,trialType,tPre,tPost,batchRun)
         %PROBEAVGIFRPLOT Plot mean aligned IFR for each channel
         %
         % probeAvgIFRplot(obj,trialType,tPre,tPost,batchRun);
         %
         % Inputs
         %  obj       - scalar or array `solBlock` object
         %  trialType - (Optional) Enumerated trial type that we want to 
         %              select for plots
         %  tPre      - (Optional) "Pre" time, relative to alignment event
         %  tPost     - (Optional) "Post" time, relative to alignment event
         %  batchRun  - (Optional) Default is false. Set true to save and
         %                 delete each figure after it is generated.
         %
         % Output
         %  fig      - Figure handle or array of `matlab.graphics.figure`
         %              handles corresponding to generated figures, one for
         %              each element of `obj`
         
         if nargin < 5
            batchRun = false;
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
            for ii = 1:numel(obj)
               probeAvgIFRplot(obj(ii),trialType,tPre,tPost,batchRun);
            end
            return;
         end
         
         nTrial = sum(obj.TrialType == trialType);
         edgeVec = [tPre,tPost];   
         [a_loc,b_loc] = solBlock.getDefault('probe_a_loc','probe_b_loc');
         
         
         
         aFig = figure('Name',sprintf('%s - %s Average IFR (%s trials)',...
            obj.Name,a_loc,char(trialType)),...
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
            avgIFRplot(c(idx),trialType,edgeVec,1,false);
         end
         suptitle(sprintf('%s (n = %g)',a_loc,nTrial));
         
         bFig = figure('Name',sprintf('%s - %s Average IFR (%s trials)',...
            obj.Name,b_loc,char(trialType)),...
            'Units','Normalized',...
            'Position',[0.5 0.1 0.4 0.8],...
            'Color','w');
         
         c = obj.Children([obj.Children.Hemisphere] == cfg.Hem.Right);
         for ii = 1:numel(c)
            idx = find(contains({c.Name},obj.Layout{ii}),1,'first');
            subplot(round(numel(obj.Layout)/4),4,ii);
            avgIFRplot(c(idx),trialType,edgeVec,1,false);
         end
         suptitle(sprintf('%s (n = %g)',b_loc,nTrial));
         
         if batchRun
            subf = cfg.default('subf');
            id = cfg.default('id');
            
            outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.probeplots);
            if exist(outpath,'dir')==0
               mkdir(outpath);
            end
            
            savefig(aFig,fullfile(outpath,[obj.Name id.probeavgifr '_' char(trialType) '-A.fig']));
            savefig(bFig,fullfile(outpath,[obj.Name id.probeavgifr '_' char(trialType) '-B.fig']));
            saveas(aFig,fullfile(outpath,[obj.Name id.probeavgifr '_' char(trialType) '-A.png']));
            saveas(bFig,fullfile(outpath,[obj.Name id.probeavgifr '_' char(trialType) '-B.png']));
            delete(aFig);
            delete(bFig);
         end

      end
      
   end
   
   % Hidden methods that are usually just called from constructor
   methods (Hidden,Access = public)
      % Parse electrode site information based on spreadsheet table
      function parseSiteInfo(obj,fname)
         %PARSESITEINFO Parses the site location for each probe
         %
         % parseSiteInfo(obj,fname);
         %
         % Inputs
         %  obj   - Scalar or array of `solBlock` objects
         %  fname - (Optional) filename of table spreadsheet 
         %           -> If not given, uses value in `cfg.default`
         %
         % Output
         %  -- none -- Updates the site location for electrodes associated
         %  with each recording block passed via `obj`
         
         if nargin < 2
            fname = solBlock.getDefault('site_location_table');
         end
         
         if ~isscalar(obj)
            for i = 1:numel(obj)
               parseSiteInfo(obj(i),fname);
            end
            return;
         end
         
         locTable = readtable(fname);
         obj.Location_Table = locTable(strcmpi(locTable.BlockID,obj.Name),:);
         obj.Location_Table.Properties.UserData = struct(...
            'type','ProbeLocation');
         obj.Location_Table.Properties.Description = ...
            'Insertion site coordinates and information regarding recording probe configuration';
         obj.Location_Table.Properties.VariableUnits = {...
            'Experiment','Port','Cortical Area','Hemisphere','Hemisphere','Orientation','mm','mm','microns','degrees'};
         obj.Location_Table.Properties.VariableDescriptions = {...
            'Experiment recording block name',...
            'Intan probe port indicating separate arrays',...
            'Area targeted by each probe (Rostral Forelimb Area; RFA; premotor) or Forelimb Sensory Cortex (S1)',...
            'Is Probe in Left or Right Hemisphere (typically contralateral to solenoid)',...
            'Is Ischemia in Left or Right Hemisphere (all same as Probe in main 7 rats)',...
            'Orientation of array clamped into stereotaxic arm (Rostral = Shank 1 is rostral; Caudal = Shank 1 is caudal)',...
            'Anteroposterior distance from bregma (mm)',...
            'Mediolateral distance from bregma (mm)', ...
            'Insertion depth of highest channel (microns)',...
            'Angle of probe (degrees) with respect to horizontal from bregma, positive is clockwise direction'};
      end
      
      % Parse solenoid location information based on spreadsheet table
      function parseSolenoidInfo(obj,fname)
         %PARSESOLENOIDINFO Parses solenoid location info from table
         %
         % parseSolenoidInfo(obj);
         % parseSolenoidInfo(obj,fname); -> Different from `cfg.default`
         %
         % Inputs
         %  obj   - Scalar or array `solBlock` object
         %  fname - (Optional) if using a different filename than default
         %                     specified by 
         %                       `cfg.default('solenoid_location_table');`
         %
         % Output
         %  -- none -- Updates `solBlock.Solenoid_Location` table property
         %             for each element of `obj`
         
         if nargin < 2
            fname = solBlock.getDefault('solenoid_location_table');
         end
         
         if ~isscalar(obj)
            for i = 1:numel(obj)
               parseSolenoidInfo(obj(i),fname);
            end
            return;
         end
         
         solTable = readtable(fname);
         % Note: this requires that the file pointed to by `fname` MUST
         %       have at least one row named after the correct element of
         %       `BlockID`; if there is not exactly one row, then something
         %       is wrong since there was never more than one Solenoid
         %       used. If no solenoid was used, that is fine, it should
         %       simply be a row that has the BlockID only and all other
         %       variables (except for possibly `Notes`) empty
         blockRow = ismember(solTable.BlockID,obj.Name);
         nRow = sum(blockRow);
         if nRow == 1
            obj.Solenoid_Location = solTable(blockRow,:);
         elseif nRow == 0 % Do some error checking on input data table
            error(['SOLENOID:' mfilename ':BadDataTable'],...
               ['\n\t->\t<strong>[PARSESOLENOIDINFO]</strong> ' ...
                'Missing row in spreadsheet (%s) for block ' ...
                '<strong>%s</strong\n\t\t\t\t' ...
                '(Should contain exactly <strong>one</strong> row ' ...
                'with this BlockID)\n'],fname,obj.Name);
         else
            error(['SOLENOID:' mfilename ':BadDataTable'],...
               ['\n\t->\t<strong>[PARSESOLENOIDINFO]</strong> ' ...
                'Multiple rows in spreadsheet (%s) for block ' ...
                '<strong>%s</strong\n\t\t\t\t' ...
                '(Should only contain <strong>one</strong> row ' ...
                'per unique BlockID)\n'],fname,obj.Name);
         end
      end
      
      % Set (construct) the child CHANNEL objects
      function Children = setChannels(obj,subf,id)
         %SETCHANNELS Creates child `solChannel` objects
         %
         % Children = setChannels(obj,subf,id);
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
         %  Children - `solChannel` scalar or array that populates the
         %             `solBlock.Children` property of each element in
         %             `obj` input argument.
         
         % Parse input arguments
         if nargin < 3
            id = solBlock.getDefault('id');
         end
         if nargin < 2
            subf = solBlock.getDefault('subf');
         end
         % Handle object array input
         if numel(obj) > 1
            Children = solChannel.empty;
            for ii = 1:numel(obj)
               Children = [Children; ...
                  obj(ii).setChannels(subf,id)]; %#ok<AGROW>
            end
            return;
         end
         
         % Load channel RAW data INFO file
         raw = fullfile(obj.folder,[obj.Name subf.raw],[obj.Name id.info]);
         in = load(raw);
         % Construct child CHANNEL array
         fprintf(1,['\n\t->\t<strong>[SOLBLOCK.SETCHANNELS]:</strong> ' ...
            'Adding <strong>solChannel</strong> objects to ' ...
            'solBlock <strong>%s</strong>...000%%\n'],obj.Name);
         nCh = numel(in.RW_info);
         Children = solChannel(nCh);
         locData = obj.Location_Table;
         for iCh = 1:nCh
            Children(iCh) = solChannel(obj,in.RW_info(iCh),locData);
            fprintf(1,'\b\b\b\b\b%03d%%\n',round((iCh/nCh)*100));
         end
      end
      
      % Set the site layout pattern and site depth
      function setLayout(obj,L,fname)
         %SETLAYOUT Set the site layout pattern and site depth
         %
         % setLayout(obj);
         % setLayout(obj,L);
         % setLayout(obj,L,fname);
         %
         % Inputs
         %  obj   - `solBlock` or array of `solBlock` objects
         %  L     - (Optional) Layout of channels (names)
         %              -> Matrix is cell array of char vectors arranged as
         %                 m x k, where m is # channels per shank and k is
         %                 # shanks, and element (m,k) is the m-th deepest
         %                 (e.g. 1,k is the most-dorsal on shank k) channel
         %                 on shank k.
         %  fname - (Optional) Excel spreadsheet filename with locations of
         %                       probes for this experiment. If not
         %                       provided, uses value in 
         %                       `cfg.default('site_location_table');`
         %
         % Output
         %  -- none -- (Sets `Layout` and `Depth` properties of solBlock)
         
         if nargin < 3
            fname = solBlock.getDefault('site_location_table');
         end
         if nargin < 2
            L = solBlock.getDefault('L');
         end
         if numel(obj) > 1
            for ii = 1:numel(obj)
               setLayout(obj(ii),L,fname);
            end
            return;
         end
         
         obj.Layout = L;    % relative offset of each channel (microns) 
         parseSiteInfo(obj,fname);
      end
      
      % Set Metadata file names
      function setMetaNames(obj,subf,id)
         %SETMETANAMES Set metadata file names
         %
         % setMetaNames(obj,subf,id);
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
         
         if nargin < 2
            subf = cfg.default('subf');
         end
         
         if nargin < 3
            id = cfg.default('id');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).setMetaNames(subf,id);
            end
            return;
         end
         sync_path = fullfile(obj.folder,[obj.Name subf.dig]);
         
         obj.sol = fullfile(sync_path,[obj.Name id.sol]);
         obj.trig = fullfile(sync_path,[obj.Name id.trig]);
         obj.iso = fullfile(sync_path,[obj.Name id.iso]);
         obj.icms = fullfile(sync_path,[obj.Name id.icms]);
         obj.trial = fullfile(sync_path,[obj.Name id.trial]);
         obj.stim = fullfile(sync_path,[obj.Name id.stim_info]);
      end
      
      % Set sample rate (fs) for this object
      function setSampleRate(obj,fs)
         %SETSAMPLERATE Set sample rate (fs) for this object
         %
         % setSampleRate(obj);     -> Parses from files
         % setSampleRate(obj,fs);  -> Specify sample rate explicitly
         %
         % Inputs
         %  obj - Scalar or array of `solBlock` objects
         %  fs  - (Optional) Can either be:
         %           * Scalar numeric - sample rate of recording amps
         %           * Struct - struct with field `gen` from
         %                       cfg.default('id') struct, which is then
         %                       used to load the file that contains the
         %                       `fs` data for amplifier that was extracted
         %                       from recording binaries.
         %
         % Output
         %  -- none -- Sets the `solBlock.fs` property
         
         % Parse input arguments
         if nargin < 2
            fs = solBlock.getDefault('id');
         end
         
         % Handle object input array
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).setSampleRate(fs);
            end
            return;
         end
         
         if isstruct(fs) % If it's a struct, then should be 'id' from cfg
            in = load(fullfile(obj.folder,[obj.Name fs.gen]),'info');
         elseif isnumeric(fs) % If it's numeric, just set and return
            obj.fs = fs;
            return;  
         else % Otherwise just use default cfg.id struct
            fprintf(1,'Could not parse ''fs'' input.\n');
            fprintf(1,'-->\tExtrapolating fs from data.\n');
            in = load(fullfile(obj.folder,[obj.Name fs.gen]),'info');
         end
         
         obj.fs = in.info.frequency_pars.amplifier_sample_rate;
      end
      
      % Set solenoid ON and OFF times (or) 
      function setSolenoidLatencies(obj,onsetLatency,offsetLatency)
         %SETSOLENOIDLATENCIES Set solenoid onset and offset times
         %
         % setSolenoidLatencies(obj,onsetLatency,offsetLatency);
         %
         % Inputs
         %  obj           - SCALAR-only `solBlock` object 
         %  onsetLatency  - onset latency of solenoid (relative time of 
         %                    when it was energized; sec)
         %  offsetLatency - offset latency of solenoid (relative time of
         %                    when it current pulse ended; sec)
         %
         % Output
         %  -- none -- Create association to relative timing of solenoid
         %              stimulus for trials in solBlock `obj`
         
         if ~isscalar(obj)
            error(['SOLENOID:' mfilename ':BadInputSize'],...
               ['\n\t->\t<strong>[SETSOLENOIDLATENCIES]:</strong> ' ...
                '`setSolenoidOnOffTimes` is a method for SCALAR ' ...
                '`solBlock` objects only']);
         end
         
         % If specified, just set those properties
         if nargin == 3
            if isnumeric(onsetLatency) && isnumeric(offsetLatency)
               obj.Solenoid_Onset_Latency = onsetLatency;
               obj.Solenoid_Offset_Latency = offsetLatency;
               return;
            else
               fprintf(1,...
                  '''onsetLatency'' and ''offsetLatency'' must be numeric.\n');
            end
         end
         
         % Get solenoid onset/offset times
         tSolOnset = obj.getSolOnset(obj.fs/4);
         tSolOnsetAll = obj.getSolOnset;
         tSolOffset = obj.getSolOffset(obj.fs/4);
         tSolOffsetAll = obj.getSolOffset;
         
         % Get "trigger" for first solenoid trial (to parse onset/offset)
         tTrig = obj.getClosestTrialOnset(tSolOnsetAll);

         % Set onset latencies
         if isempty(tSolOnsetAll)
            obj.Solenoid_Onset_Latency = nan;
         else
            nTrain = round(numel(tSolOnsetAll)/numel(tSolOnset));
            obj.Solenoid_Onset_Latency = nan(1,nTrain);
            for ii = 1:nTrain
               obj.Solenoid_Onset_Latency(ii) = tSolOnsetAll(ii) - tTrig;
            end
         end
         
         % Set offset latencies
         if isempty(tSolOffsetAll)
            obj.Solenoid_Offset_Latency = nan;
         else
            nTrain = round(numel(tSolOffsetAll)/numel(tSolOffset));
            obj.Solenoid_Offset_Latency = nan(1,nTrain);
            for ii = 1:nTrain
               obj.Solenoid_Offset_Latency(ii) = tSolOffsetAll(ii) - tTrig;
            end
         end
      end
      
      % Set the "pre" alignment, "post" alignment, and histogram bin width
      function setSpikeBinEdges(obj,tPre,tPost,binWidth)
         %SETSPIKEBINEDGES Set "pre" and "post" binning vector for spikes
         %
         % setSpikeBinEdges(obj);
         % setSpikeBinEdges(obj,tPre,tPost);
         % setSpikeBinEdges(obj,tPre,tPost,binWidth);
         % 
         % Inputs
         %  obj      - scalar or array `solBlock` object
         %  tPre     - time (seconds) for "pre-stimulus" epoch (negative)
         %  tPost    - time (seconds) for "post-stimulus" epoch (positive)
         %  binWidth - width of each histogram bin (seconds)
         %
         % Output
         %  -- none -- Create binning vector association for spike
         %  histogram creation.
         
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
               setSpikeBinEdges(obj(ii),tPre,tPost,binWidth);
            end
            return;
         end
         
         obj.edges = tPre:binWidth:tPost;
         setSpikeBinEdges(obj.Children,tPre,tPost,binWidth);
      end
      
      % Set ICMS times
      function setStims(obj,tStim,icms_channel_index)
         %SETSTIMS Set ICMS stimulus times
         %
         % setStims(obj); -> Called in constructor
         % setStims(obj,tStim);
         % setStims(obj,tStim,icms_channel_index);
         %
         % Inputs
         %  obj                  - SCALAR `solBlock` array
         %  tStim                - Stim times array
         %  icms_channel_index   - Index of channel used to deliver ICMS
         %
         % Output
         %  -- none -- Sets the `solBlock.ICMS_Channel_Index`,
         %             `solBlock.ICMS_Onset_Latency`, and
         %             `solBlock.ICMS_Channel_Name` properties.
         %  
         % See also: solBlock.parseStimDistance
         
         if ~isscalar(obj)
            error(['SOLENOID:' mfilename ':BadInputSize'],...
               ['\n\t->\t<strong>[SETSTIMS]:</strong> ' ...
                '`setStims` is a method for SCALAR ' ...
                '`solBlock` objects only']);
         end
         
         if nargin < 2
            [tStim,icms_channel_index] = getStims(obj.Children);
         elseif nargin < 3
            [~,icms_channel_index] = getStims(obj.Children);
         end
         
         % Get ICMS info
         obj.ICMS_Channel_Index = icms_channel_index;
         if isnan(icms_channel_index)
            obj.ICMS_Channel_Name = "None";
         else
            obj.ICMS_Channel_Name = vertcat(...
               obj.Children(icms_channel_index).Name);
         end
         
         % Set the onset latency 
         if isempty(tStim)
            obj.ICMS_Onset_Latency = nan;
         else
            tTrig = obj.getClosestTrialOnset(tStim(1,:));
            tTrial = obj.getTrials;
            nTrain = round((size(tStim,2)*3)/(numel(tTrial)*2));
            obj.ICMS_Onset_Latency = nan(nTrain,size(tStim,1));
            for ii = 1:nTrain
               for ik = 1:size(tStim,1)
                  obj.ICMS_Onset_Latency(ii,ik) = tStim(ik,ii) - tTrig;
               end
            end
         end
         
         % Set the distance to any stimulation channels for all child obj
         parseStimDistance(obj);
      end
      
      % Set Trial times
      function setTrials(obj,tTrials)
         %SETTRIALS Set trial times for scalar or array of objects
         %
         % setTrials(obj); -> Parse times using `t = getTrials(obj,true);`
         % setTrials(obj,tTrials); -> Specify times manually
         %
         % Inputs
         %  obj     - Scalar or array of `solBlock` objects
         %  tTrials - (Optional): vector of trial times (sec) for `obj`; if
         %                        `obj` is array, should be given as cell
         %                        array of trial times for each element of
         %                        `obj`
         %
         % Output
         %  -- none -- Sets the `solBlock.Trials` property and invokes the
         %              `parseTrialType` method on each element of `obj`
         %
         % See Also: solBlock.parseTrialType
         
         if nargin < 2
            tTrials = [];
         end
         
         % Parse array input
         if numel(obj) > 1
            if ~iscell(tTrials)
               error(['SOLENOID:' mfilename ':BadSyntax'],...
                  ['\n\t->\t<strong>[SETTRIALS]:</strong> ' ...
                   'If `obj` is passed as array to `setTrials`, then ' ...
                   'if `tTrials` is specified, must be as a cell array ' ...
                   'with each cell corresponding to element of `obj`\n']);
            end
            for ii = 1:numel(obj)
               obj(ii).setTrials(tTrials{ii});
            end
            return;
         end
         
         % Get TRIALS and UPDATE PROP
         if isempty(tTrials)
            tTrials = getTrials(obj,true);
            if isempty(tTrials)
               fprintf(1,'%s: no TRIALS registered.\n',obj.Name);
               return;
            end
         else
            obj.Trials = tTrials;
         end
         
         % Parse the type for each trial
         parseTrialType(obj);
         
      end
      
   end
   
   % Helper methods that are called from other functions
   methods (Access = private)
      % Parse BLOCK name using recording folder path
      function [Name,Index] = parseName(obj)
         %PARSENAME Parse BLOCK name using recording folder path
         %
         % [Name,Index] = obj.parseName();
         %
         % Inputs
         %  obj   - `solBlock` object or array of such objects
         %
         % Output
         %  Name  - Name of recording block (char array). If `obj` is
         %           nonscalar, then this is returned as cell array of same
         %           dimension as `obj`
         %  Index - Same as Name regarding size, except this is a numeric
         %           array representing the block index corresponding to
         %           each Block.
         
         if numel(obj) > 1
            Name = cell(size(obj));
            Index = nan(size(obj));
            for ii = 1:numel(obj)
               [Name{ii},Index(ii)] = obj(ii).parseName;
            end
            return;
         end
         name = strsplit(obj.folder,filesep);
         Name = name{end};
         tag = strsplit(Name,'_');
         Index = str2double(tag{end});
      end
      
      % Parse distance to stimulation electrode
      function parseStimDistance(obj)
         %PARSESTIMDISTANCE Parse distance to stimulation electrode
         %
         % parseStimDistance(obj); -> Called in `solBlock.setStims`
         %
         % Inputs
         %  obj - Scalar or array `solBlock` object
         %
         % Output
         %  -- none -- Updates `solChannel.Stim_Distance_Table` property of
         %              each element of `obj.Children`
         %
         % See also: solBlock.setChildren, solBlock.setStims
         
         if ~isscalar(obj)
            for i = 1:numel(obj)
               parseStimDistance(obj(i));
            end
            return;
         end
         
         if strcmp(obj.ICMS_Channel_Name(1),"None")
            setStimChannelDistance(obj.Children,"None",nan,nan,nan);
         else
            [ap,ml,depth] = getLocation(obj.Children,...
               obj.ICMS_Channel_Name);
            setStimChannelDistance(obj.Children,...
               obj.ICMS_Channel_Name,ap,ml,depth);
         end
      end
      
      % Parse trial FILE
      function successful_parse_flag = parseTrials(obj)
         %PARSETRIALS Parse trial file
         %
         % Note: 
         %  This method is just there because Max once or twice forgot
         %  to enable the analog inputs on a couple of recording blocks. 
         %  Fortunately, that information can be reconstructed from the 
         %  combination of ICMS and SOLENOID digital streams, so this is 
         %  just there to "fix" a few "bad" recordings.
         %
         % successful_parse_flag = parseTrials(obj);
         
         if numel(obj) > 1
            successful_parse_flag = false(numel(obj),1);
            for i = 1:numel(obj)
               successful_parse_flag(i) = parseTrials(obj(i));
            end
            return;
         end
         successful_parse_flag = false;
         fprintf(1,'Parsing TRIAL stream for %s...',obj.Name);
         
         % Get a vector of HIGH indices, which will be used relative to
         % each computed TRIAL index to set the stream HIGH.
         trial_high_duration = cfg.default('trial_high_duration');
         i_trial_vec = 0:round(trial_high_duration*1e-3 * obj.fs);
         
         % Parse solenoid and ICMS onset indices
         iSol = round(obj.getSolOnset * obj.fs);
         iICMS = round(obj.getICMS * obj.fs);
         
         if isempty(iICMS)
            fprintf(1,'\n-->Could not parse trials for %s\n',obj.Name);
            return;
         end
                 
         % Initialize data struct (to save)
         in = load(obj.icms);
         out = struct;
         out.data = zeros(size(in.data));
         out.fs = in.fs;
         
         % Get the solenoid lag (should always be after ICMS)
         solLag = min(min(abs(iICMS - iSol(1))),min(abs(iICMS - iSol(2))));  
         
         % Cycle through all ICMS, setting vector to HIGH
         for k = 1:numel(iICMS)
            vec = i_trial_vec + iICMS(k);
            vec = vec((vec >= 1) & (vec <= numel(out.data)));
            out.data(vec) = 1;
         end
         
         % Cycle through all solenoid, setting vector to HIGH
         for k = 1:numel(iSol)
            vec = i_trial_vec + iSol(k) - solLag;
            vec = vec((vec >= 1) & (vec <= numel(out.data)));
            out.data(vec) = 1;
         end
         
         % Save data struct using TRIAL file name
         save(obj.trial,'-struct','out');
         fprintf(1,'successful\n');
         successful_parse_flag = true;
      end
      
      % Parse the trial TYPE (for new CYCLE setup)
      function parseTrialType(obj,tTrials,thresh)
         %PARSETRIALTYPE Parses the enumerated TYPE for each trial
         %
         % parseTrialType(obj,tTrials,thresh);
         %
         % Inputs
         %  obj     - Scalar or array of `solBlock` objects
         %  tTrials - Time of each trial (seconds)
         %  thresh  - Threshold (seconds) for distinguishing between trials
         %
         % Output
         %  Associates the TYPE with each trial in `obj.TrialType` property
         
         if ~isscalar(obj)
            error(['SOLENOID:' mfilename ':BadInputSize'],...
               ['\n\t->\t<strong>[PARSETRIALTYPE]:</strong> ' ...
                '`parseTrialType` is a method for SCALAR ' ...
                '`solBlock` objects only']);
         end
         if nargin < 3
            thresh = solBlock.getDefault('trial_duration');
         end
         
         if nargin < 2
            tTrials = obj.getTrials;
         end
         
         tStim = getICMS(obj);
         tSol = getSolOnset(obj);
         
         obj.TrialType = nan(numel(tTrials),1);
         for ii = 1:numel(tTrials)
            dStim = min(abs(tStim - tTrials(ii)));
            dSol = min(abs(tSol - tTrials(ii)));
            
            if (dStim < thresh) && (dSol < thresh)
               obj.TrialType(ii) = cfg.TrialType('SolICMS');
            elseif dStim < thresh
               obj.TrialType(ii) = cfg.TrialType('ICMS');
            elseif dSol < thresh
               obj.TrialType(ii) = cfg.TrialType('Solenoid');
            else
               obj.TrialType(ii) = cfg.TrialType('Catch');
            end
         end
      end
   end
   
   % Static methods of SOLBLOCK class 
   methods (Static = true)
      % Return empty `solBlock` object
      function obj = empty()
         %EMPTY  Return empty `solBlock` object
         %
         % obj = solBlock.empty();
         %
         % Use this to initialize an empty array of `solBlock` for
         % concatenation, for example.
         
         obj = solBlock(0);
      end
      
      % Return indexing array with correct dimensions
      function Y = pruneTruncatedSegments(X)
      %PRUNETRUNCATEDSEGMENTS Return indexing array with correct dimensions
      %
      % Returns indexing matrix Y from binary vector X, where X switches
      % from LOW to HIGH to indicate a contiguous segment related to some
      % event of interest. Because if a recording is stopped early these
      % segments can be truncated prematurely, this function checks to
      % ensure there are the same number of HIGH samples in each detected
      % "segment" and then returns the corresponding sample indices in the
      % data matrix Y, where each row corresponds to a segment and each
      % column is the sample index of a consecutive sample of interest.
      %
      %  Y = solBlock.pruneTruncatedSegments(X);
      %
      %  Inputs
      %   X - Thresholding matrix indicating that a stimulus was present
      %
      %  Output
      %   Y - Indexing matrix corresponding to rising/falling edges of X
      
         data = find(X > cfg.default('analog_thresh'));
         iStart = data([true, diff(data) > 1]);
         iDiff = iStart(2)-iStart(1);
         iStart = iStart([true, diff(iStart) == iDiff]);
         
         Y = nan(numel(iStart),iDiff);
         for i = 1:numel(iStart)
            Y(i,:) = iStart(i):(iStart(i)+iDiff-1);
         end
         
      end
      
      % Wrapper function to get variable number of default fields 
      function varargout = getDefault(varargin)
         %GETDEFAULT Return defaults parameters for `solBlock`
         %
         %  varargout = solBlock.getDefault(varargin);
         %  e.g.
         %     param = solBlock.getDefault('paramName');
         %     [p1,...,pk] = solBlock.getDefault('p1Name',...,'pkName');
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
   end
end