classdef solBlock < handle
%SOLBLOCK   obj = solBlock(); or obj = solBlock(ratObj,folder);
%
%  Class for organizing data from an individual recording (experiment).

% PROPERTIES
   % Unchangeable properties set on object construction
   properties (GetAccess = public, SetAccess = immutable, Hidden = false)
      Name        % Recording BLOCK name
      Parent      % Parent SOLRAT object handle
      Children    % Array of SOLCHANNEL child object handles
      Index       % From name convention: "R19-###_2019_MM_DD_[Index]"
   end
   
   % Properties that can only be changed by class methods, but can be
   % publically accessed and are not hidden.
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      fs                       % Amplifier sample rate (Hz)
      Depth                    % Overall Depth of electrodes
      Trials                   % "Trial" timestamps (NEW / CYCLE setup)
      Triggers                 % "Trigger" timestamps (OLD / original setup)
      Solenoid_Onset_Latency   % Array of solenoid extend times (1 per pulse, within a trial)
      Solenoid_Offset_Latency  % Array of solenoid retract times (1 per pulse, within a trial)
      ICMS_Onset_Latency       % Array of ICMS start times (1 per pulse, per stimulated channel)
      ICMS_Channel_Name        % Name of ICMS stimulation channel
      TrialType % Categorical array indicating trial type
   end
   
   % Properties that can be publically accessed but only changed by class
   % methods, and are also not populated in the standard object property
   % list.
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      folder               % Recording block filepath folder
      
      sol                  % Solenoid digital record file
      trig                 % "Trigger" digital record file
      iso                  % "Isoflurane" analog record file (pushbutton indicator)
      icms                 % ICMS digital record file
      trial                % "Trial" analog record file
      stim                 % "StimInfo" parsed file
      
      ICMS_Channel_Index   % Index of channel(s) delivering ICMS
      Layout               % Electrode layout (rows = depth, columns = M/L or A/P shanks)

   end
   
   % Can only be set or accessed using class methods.
   properties (Access = private)
      edges    % Time bin edges for binning histograms relative to alignment
   end

% METHODS
   % Class constructor and data-handling/parsing methods
   methods (Access = public)
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
         [obj.Name,obj.Index] = obj.parseName;
         
         % Load configured defaults
         subf = cfg.default('subf');
         id = cfg.default('id');
         L = cfg.default('L');
         depth = cfg.default('depth');
         
         % Set the electrode LAYOUT for this object
         obj.setLayout(L,depth);
         
         % Set sample rate for this object
         obj.setSampleRate(id);
         
         % Construct child CHANNEL objects
         obj.Children = obj.setChannels(subf,id);
         
         % Get other metadata         
         obj.setMetaNames(subf,id);
         
         % Parse trial times
         obj.setTrials;
         
         % Set ICMS stimuli
         obj.setStims;
         
         % Set the solenoid latencies
         obj.setSolenoidLatencies;
         fprintf(1,'\n -- \n');
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
      
      % Parse trile FILE
      function successful_parse_flag = parseTrials(obj)
         %PARSETRIALS Parse trial file
         %
         % Parse trial FILE (if not present, because Max is dumb and forgot
         % to enable the analog inputs on a couple of recording blocks); it
         % can be reconstructed from the combination of ICMS and SOLENOID 
         % digital streams, so this is just there to "fix" a few "bad"
         % recordings.
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
         
         if numel(obj) > 1
            error('parseTrialType is a method for SCALAR solBlock objects only.');
         end
         if nargin < 3
            thresh = cfg.default('trial_duration');
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
         %GETDEFAULT Return default variable
         %
         % varargout = solBlock.getDefault(varargin);
         %
         % See also: cfg.default
         
         % Parse input
         if nargin > nargout
            error('More inputs specified than requested outputs.');
         elseif nargin < nargout
            error('More outputs requested than inputs specified.');
         end
         
         % Collect fields into output cell array
         varargout = cell(1,nargout);
         [varargout{:}] = cfg.default(varargin{:});  
      end
   end
   
   % "Graphics" methods
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
         
%          obj.parseStimuliTimes;
         
         edgeVec = [tPre,tPost];        
         fig = avgLFPplot(obj.Children(subset),trialType,edgeVec);
         
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
      %        * `XLoc`       - X-coordinate (mm) relative to bregma
      %                          (anteroposterior distance)
      %        * `YLoc`       - Y-coordinate (mm) relative to bregma
      %                          (mediolateral distance)
      %        * `Depth`      - Depth of recording channel (depends on
      %                          channels, which are at different depths on
      %                          individual recording shanks, as well as
      %                          the overall insertion depth)
      %        * `TrialType`- {'Solenoid','ICMS', or 'Solenoid+ICMS'}
      %        * `Spikes` - Binned spike counts relative to alignment for a
      %                       single channel.
      %        * `LFP`    - LFP time-series relative to alignment for a
      %                       single channel.
      %        * `Notes` - Most-likely empty, but allows manual input of
      %                    notes or maybe a notes struct? Basically
      %                    something that lets you manually add "tags" to
      %                    the data rows.
      
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
      
      %number of rows = number of channels * number of trials
      trialID = obj.Name; % 
      nChannels = length(obj.Children);
      trialTypes = obj.TrialType;
      nTrials = length(obj.TrialType);
      nRows = nChannels * nTrials;
      RowID = strings([nRows 1]);

      alphabet = strcat('a':'z','A':'Z');

      for i = 1:nRows
          randstr = alphabet(randi(length(alphabet), 1, 10));
          RowID(i) = strcat("ROWID_",randstr);
      end

      GroupID = repelem(trialTypes, nChannels);

      parseID = split(trialID, '_');
      AnimalID = string(repelem(parseID(1),nRows)');
      BlockID = string(repmat(join(parseID(2:end),'_'),nRows,1));
      TrialID = string(repmat(trialID,nRows,1));

      % Group = categorical(GroupID,1:3,{'Solenoid','ICMS','Solenoid+ICMS'});
      Group = cfg.TrialType(GroupID); % Uses previously-defined enumeration TrialType class

      % SolChannel stuff

      Channel = repmat(1:nChannels,1,nTrials)';

      depthArr = zeros(nChannels,1);
      hemisphereArr = zeros(nChannels,1);
      impedenceArr = zeros(nChannels,1);
      nameArr = strings([nChannels 1]);
      
      for i = 1:nChannels
          depthArr(i) = obj.Children(i,1).Depth;
          hemisphereArr(i) = obj.Children(i,1).Hemisphere;
          impedenceArr(i) = obj.Children(i,1).Impedance;
          nameArr(i) = obj.Children(i,1).Name;
      end

      ProbeDepth = repmat(depthArr,nTrials,1);
      Hemisphere = repmat(hemisphereArr,nTrials,1);
      Impedance = repmat(impedenceArr,nTrials,1);
      Names = string(repmat(nameArr,nTrials,1));

      trialNumber = repelem(1:nTrials,nChannels)';
      % make the table 

      blockTable = table(TrialID, BlockID, RowID, AnimalID, GroupID, ...
          Group, Channel, trialNumber, ...
          Names, Hemisphere, ProbeDepth, Impedance);

      % % Commented part below has to change % %
      %   (Won't work when there are multiple Blocks for each Rat ) %
      
      % get the Histogram (spikes; PETH) and LFP data timeseries
      binCell = {nRows,1};
      %for loop over the whole table
      for iRow = 1:height(blockTable)
          %first need to get which channel that row is
          iChan = table2array(blockTable(iRow,'Channel'));
          %get the binned spikes for that channel, allTrials is 118x500 double
          % Ex 118 --> Number of trials
          % Ex 500 --> Number of time bins (-500 : 500 ms; 2-ms bins)
          allTrials = obj.Children(iChan,1).getBinnedSpikes();
          %get the specific trial in question using the trialNumber as index
          %each cell in binCell should return a 1x500 double
          binCell{iRow} = allTrials(table2array(blockTable(iRow,'trialNumber')),:);
      end

      %have to some reason transpose it to get it to be nx1
      binCellt = binCell';

      %add it to the table
      blockTable.Spikes = binCellt;

      % ChannelID and ProbeID
      % this variable/section will need to be changed
      % unsure how these filenames correspond with each of the channels from
      % solRat object
      % is P1 Ch 0 always == channel 1?
      wav_sneo_folder = strcat(obj.Name,'_wav-sneo_CAR_Spikes'); 

      probeList = {};
      chList = [];

      %gets all mat files only
      matFiles = dir(fullfile(wav_sneo_folder,'*.mat')); 
      for i = 1:length(matFiles)
        fileName = matFiles(i).name;
        fileSplit = split(fileName, '_');
        probeList(i) = fileSplit(end-2);
        %have to get rid of the .mat on this
        chSplit = split(fileSplit(end), '.');
        chList(i) = str2double(chSplit(end-1));
      end

      % check to see if any channels were removed
      % if they werent, then assume:
      % probe 1 ch0 -> channel 1
      % probe 2 ch0 -> channel 33
      % not sure how well this holds up if its not the same shape as this data
      probeTable = strings(nRows,1);
      chTable = zeros(nRows,1);
      % +1 is needed because chList values start at 0
      if length(unique(chList))*length(unique(probeList)) == nChannels
          for iRow = 1:height(blockTable)
              %get the channel of that row
              iChan = table2array(blockTable(iRow,'Channel'));
              % if its greater than the max + 1 then subract 1
              if iChan <= max(chList) + 1
                  chTable(iRow) = iChan - 1; 
              % otherwise subract (max + 2), 2 is the offset
              else
                  chTable(iRow) = iChan - max(chList) - 2;            
              end
              probeTable(iRow) = probeList{iChan};
          end

      else
          warning(['SOLENOID:' mfilename ':DataFormat'],...
             ['\n\t->\t<strong>[MAKETABLES]:</strong> ' ...
              'Channel might have been removed. The indexing for ' ...
              'ChannelID & ProbeID may be incorrect']);
      end

      %add it to the table
      blockTable.ChannelID = chTable;
      blockTable.ProbeID = probeTable;

      % move the variable around so its next to the other channel stuff
      blockTable = movevars(blockTable,'ProbeID','After','Channel');
      blockTable = movevars(blockTable,'ChannelID','After','ProbeID');

      % Load in the _DS mat files and parse them using timestamps

      % Default PETH parameters
      tpre = -0.250;
      tpost = 0.750;
      % fs is 1000 for the _DS data
      %fsDS = 1000;
      timeStamps = obj.Trials;

      %using fs and the timeStamps create a nTrials x 2 array of indices 
      % first value is the start of that 1s window (in samples), second is end
      % these indices can then be used to index into mat files and grab data
      DS_folder = strcat(obj.Name,'_DS');

      %gets all mat files only
      matFiles = dir(fullfile(DS_folder,'*.mat')); 
      
      firstMat = matFiles(1).name; %load the first mat file to get the fs
      fsDS = getfield(load(firstMat,'fs'),'fs');
      
      windowInd = zeros(nTrials, 2);
      for i = 1:nTrials
          % should I round up or down? 
          % the boundary is never on a whole number index
          % right now round down on the beginning, and round up on the end
          % tpre is a negative number, so add it 
          windowInd(i,1) = floor(timeStamps(i)*fsDS+(tpre*fsDS));
          windowInd(i,2) = ceil(timeStamps(i)*fsDS+(tpost*fsDS));
      end

      %now use windowInd to access the mat files and parse the data
      %using cells because some of the windows be off by 1 due to rounding
      lfp = cell(nRows,1);
      % loop through the .mat files in _DS
      % iterate through all the files
      for i = 1:length(matFiles)
        fileName = matFiles(i).name;
        data = getfield(load(firstMat,'data'),'data');%get data from .mat
        fileSplit = split(fileName, '_');
        probe = fileSplit(end-2);
        %have to get rid of the .mat on this
        chSplit = split(fileSplit(end), '.');
        ch = str2double(chSplit(end-1));

        % find the rows where you have that channel and probe
        % there might be a faster way to do this? not sure
        % iterate through all rows
        for iRow = 1:height(blockTable)
            % if the channel is correct
            chI = table2array(blockTable(iRow,'ChannelID'));
            if chI == ch
                % if the probe is correct
                if strcmp(table2array(blockTable(iRow,'ProbeID')), cell2mat(probe))

                    % grab the indicies we parsed earlier and get that data
                    ind = table2array(blockTable(iRow,'trialNumber'));
                    t = windowInd(ind,:);
                    %data array is loaded above from filename
                    lfp{iRow} = data(t(1):t(2));
                end
            end
        end

      end

      % add it to the table
      blockTable.LFP = lfp;
         
      
      end %%%% End of makeTables%%%%
      
      % Plot the peri-event time histogram for each channel, save the
      % figure, and close the figure once it has been saved.
      function batchPETH(obj,trialType,tPre,tPost,binWidth,subset)
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

         subf = cfg.default('subf');
         id = cfg.default('id');
         
         outpath = fullfile(obj.folder,[obj.Name subf.figs],subf.peth);
         if exist(outpath,'dir')==0
            mkdir(outpath);
         end
         
%          obj.parseStimuliTimes
         
         for ii = subset

            f = PETH(obj.Children(ii),edgeVec,trialType,ii);
            
            savefig(f,fullfile(outpath,[obj.Name '_' obj.Children(ii).Name ...
               char(trialType) '_' id.peth '.fig']));
            saveas(f,fullfile(outpath,[obj.Name '_' obj.Children(ii).Name ...
               char(trialType) '_' id.peth '.png']));
            
            delete(f);
            
         end
      end
      
      % Plot the peri-event time histogram for each channel, organized
      % using the channel configuration (LAYOUT) of the electrode.
      function probePETH(obj,trialType,tPre,tPost,binWidth,batchRun)
         if nargin < 6
            batchRun = false;
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
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               probePETH(obj(ii),trialType,tPre,tPost,binWidth,batchRun);
            end
            return;
         end
         
         
         nTrial = sum(obj.TrialType == trialType);
         
         edgeVec = tPre:binWidth:tPost;   
         
         [a_loc,b_loc] = solBlock.getDefault('probe_a_loc','probe_b_loc');
         
         aFig = figure('Name',sprintf('%s - %s PETH (%s trials)',...
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
            PETH(c(idx),edgeVec,trialType,1,false);
         end
         suptitle(sprintf('%s (n = %g)',a_loc,nTrial));
         
         bFig = figure('Name',sprintf('%s - %s PETH (%s trials)',...
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
            subf = cfg.default('subf');
            id = cfg.default('id');
            
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
      
      % Plot the peri-event time histogram (and leave it open)
      function fig = PETH(obj,trialType,tPre,tPost,binWidth,subset)
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
         
%          obj.parseStimuliTimes;
         
         edgeVec = tPre:binWidth:tPost;         
         fig = PETH(obj.Children(subset),edgeVec,trialType);
         
      end
      
      % Plot spike raster for all the child CHANNELS of this recording,
      % aligned to the solenoid trials.
      function plotRaster(obj,trialType,tPre,tPost,binWidth)
         if nargin < 2
            trialType = cfg.TrialType('All');
         end
         
         if nargin == 5
            setSpikeBinEdges(obj,tPre,tPost,binWidth);
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               plotRaster(obj(ii),trialType);
            end
            return;
         end
         
         plotRaster(obj.Children,trialType);
         
      end
      
      
      % Plot the LFP coherence for each channel. Organize subplots by
      % channel configuration (LAYOUT) of the electrode.
      function probeLFPcoherence(obj,trialType,tPre,tPost)
         
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
      
      % Plot the mean aligned LFP for each channel. Organize subplots by
      % channel configuration (LAYOUT) of the electrode.
      function probeAvgLFPplot(obj,trialType,tPre,tPost,batchRun)
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
      
      % Plot the mean aligned IFR for each channel. Organize subplots by
      % channel configuration (LAYOUT) of the electrode.
      function probeAvgIFRplot(obj,trialType,tPre,tPost,batchRun)
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
   
   % "Get" methods
   methods (Access = public)
      % Returns the closest timestamp of a trial ONSET, given an input
      % vector of times (seconds)
      function t = getClosestTrialOnset(obj,tVec)
         ts = obj.getTrials;
         [~,idx] = min(abs(ts - tVec(1)));
         t = ts(idx);
      end
      
      % Get the normalized position for current figure placement (to make a
      % cascaded tile of figures across the screen when multiple figures
      % will be generated by a method)
      function pos = getFigPos(obj,ii)
         pos = cfg.default('figpos');
         scl = cfg.default('figscl');
         pos(1) = pos(1) + scl * (ii/numel(obj.Children));
         pos(2) = pos(2) + scl * (ii/numel(obj.Children));
      end
      
      % Get ICMS times (for new CYCLE setup); if obj is an array, returns
      % a cell array where each array element contains a vector of
      % timestamps for the onset of each ICMS within a recording BLOCK.
      function ts = getICMS(obj)         
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
      
      % Get TRIAL times (for new CYCLE setup); if obj is an array, returns
      % a cell array where each array element contains a vector of
      % timestamps for the onset of each TRIAL within a recording BLOCK.
      % Second argument, 'updateTrialsProp' defaults to false unless
      % otherwise specified.
      function ts = getTrials(obj,updateTrialsProp)
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
         in = load(obj.trig,'data');
         if sum(in.data) == 0
            ts = [];
            return;
         end
         
         data = find(in.data > 0);
         ts = data([true, diff(data) > 1]) ./ obj.fs;
         obj.Triggers = ts;
      end
      
      % Get times when solenoid is turned from LOW to HIGH (e.g. when it
      % just started extending)
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
      
      % Get times when solenoid is turned from HIGH to LOW (e.g. when it
      % just started retracting)
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
      
      % Return the spike bin (histogram) edge times
      function edges = getSpikeBinEdges(obj)
         if numel(obj) > 1
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
      
   end
   
   % "Set" methods
   methods (Access = public)
      % Set (construct) the child CHANNEL objects
      function Children = setChannels(obj,subf,id)
         % Parse input arguments
         if nargin < 3
            id = cfg.defaults('id');
         end
         if nargin < 2
            subf = cfg.defaults('subf');
         end
         % Handle object array input
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).setChannels(subf,id);
            end
            return;
         end
         
         % Load channel RAW data INFO file
         in = load(fullfile(obj.folder,...
            [obj.Name subf.raw],...
            [obj.Name id.info]));
         % Construct child CHANNEL array
         fprintf(1,'Adding CHANNEL child objects to %s...000%\n',obj.Name);
         nCh = numel(in.RW_info);
         Children = solChannel(nCh);
         for iCh = 1:nCh
            Children(iCh) = solChannel(obj,in.RW_info(iCh));
            fprintf(1,'%03g%\n',round((iCh/nCh)*100));
         end
      end
      
      % Set the depth manually (after object creation)
      function setDepth(obj,newDepth)
         obj.Depth = newDepth;
      end
      
      % Set the site layout pattern and site depth
      function setLayout(obj,L,depth)
         if nargin < 2
            L = cfg.default('L');
         end
         if nargin < 3
            depth = cfg.default('depth');
         end
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).setLayout(L,depth);
            end
            return;
         end
         obj.Depth = depth; % depth in microns of highest channel
         obj.Layout = L;    % relative offset of each channel (microns)     
      end
      
      % Set Metadata file names
      function setMetaNames(obj,subf,id)
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
      
      % Set sample rate (fs) for this object, or if not specified as an
      % input argument, parse the sample rate using default parameters. 
      % 'fs' input can also be 'id' struct from cfg.default.
      function setSampleRate(obj,fs)
         % Parse input arguments
         if nargin < 2
            fs = cfg.default('id');
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
         if numel(obj) > 1
            error('setSolenoidOnOffTimes is a method for SCALAR solBlock objects only.');
         end
         
         % If specified, just set those properties
         if nargin == 3
            if isnumeric(onsetLatency) && isnumeric(offsetLatency)
               obj.Solenoid_Onset_Latency = onsetLatency;
               obj.Solenoid_Offset_Latency = offsetLatency;
               return;
            else
               fprintf(1,'''onsetLatency'' and ''offsetLatency'' must be numeric.\n');
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
         if numel(obj) > 1
            error('setStims is a method for SCALAR solBlock objects only.');
         end
         
         if nargin < 2
            [tStim,icms_channel_index] = getStims(obj.Children);
         elseif nargin < 3
            [~,icms_channel_index] = getStims(obj.Children);
         end
         
         % Get ICMS info
         obj.ICMS_Channel_Index = icms_channel_index;
         if isnan(icms_channel_index)
            obj.ICMS_Channel_Name = 'none';
         else
            obj.ICMS_Channel_Name = {obj.Children(icms_channel_index).Name};
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
      end
      
      % Set Trial times
      function setTrials(obj,tTrials)
         if nargin < 2
            tTrials = [];
         end
         
         % Parse array input
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).setTrials(tTrials);
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
         obj.parseTrialType;
         
      end
      
   end
end