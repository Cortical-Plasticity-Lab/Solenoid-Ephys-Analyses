classdef solRat < handle
%SOLRAT Handle class to organize data collected for all animal recordings
%
%  obj = solRat;
%  obj = solRat('P:\Path\To\Data\R19-###');
%
%  Handle class to organize data collected for a specific experimental
%  animal (typically, all from the same acute surgical preparation)

% PROPERTIES   
   % Immutable properties defined during class construction
   properties (SetAccess = immutable)
      Name        % Name of this SOLRAT object ('R19-###')
      Children    % Array of SOLBLOCK child objects
   end
   
   % Properties that can be publically accessed, but must be changed using 
   % SOLRAT methods only, and don't show up by default in the property list
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      folder  % (full) file path to RAT folder
   end
   
   % Properties that can be publically accessed, but must be changed using 
   % SOLRAT methods only
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      Layout      % Probe layout for this rat
   end

   % Private "under-the-hood" properties
   properties (GetAccess = private, SetAccess = private)
      fbrowser % figBrowser class object handle
   end
   
% METHODS
   % Public methods such as graphics exports or data handling
   methods (Access = public)
      % Batch export PETH for spike alignments to stimuli
      function batchPETH(obj,trialType,tPre,tPost,binWidth)
      %BATCHPETH  Batch export PETH for spike alignments to stimuli
      %
      %  obj.batchPETH;
      %  obj.batchPETH(trialType,tPre,tPost,binWidth);
      %
      %  Inputs
      %     obj - Scalar or array of `solRat` objects
      %     trialType - (Optional) Type see `cfg.TrialType`
      %
      % Batch export (save and close) PERI-EVENT TIME HISTOGRAMS (PETH) 
      % for viewing spike counts in alignment to trials or stimuli, 
      % where each figure contains the PETH for a single channel.
      %
      % See Also: cfg.default, cfg.TrialType
         
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
            for i = 1:numel(obj)
               batchPETH(obj(i),trialType,tPre,tPost,binWidth);
            end
            return;
         end
         
         batchPETH(obj.Children,trialType,tPre,tPost,binWidth);
      end
      
      % Batch export PETH with "probe" layout subplots
      function batchProbePETH(obj,trialType,tPre,tPost,binWidth)
      %BATCHPROBEPETH Batch export PETH with "probe" layout subplots
      %
      % Batch export (save and close) PERI-EVENT TIME HISTOGRAMS (PETH) for
      % viewing spike counts in alignment to trials or stimuli, where each
      % figure contains subplots organized by probe LAYOUT for all channels
      % in a given recording BLOCK
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
            for i = 1:numel(obj)
               batchProbePETH(obj(i),trialType,tPre,tPost,binWidth);
            end
            return;
         end
         
         probePETH(obj.Children,trialType,tPre,tPost,binWidth,true);
      end
      
      % Batch export average LFP plots
      function batchProbeAvgLFPplot(obj,trialType,tPre,tPost)
      %BATCHPROBEAVGLFPPLOT Batch export average LFP plots
      %
      % Batch export (save and close) TRIAL- or STIMULUS-aligned LFP
      % average plots
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
            for i = 1:numel(obj)
               batchProbeAvgLFPplot(obj(i),trialType,tPre,tPost);
            end
            return;
         end
         
         probeAvgLFPplot(obj.Children,trialType,tPre,tPost,true);
      end
      
      % Batch export average IFR plots
      function batchProbeAvgIFRplot(obj,trialType,tPre,tPost)
      %BATCHPROBEAVGIFRPLOT Batch export average IFR plots
      %
      % Batch export (save and close) TRIAL- or STIMULUS-aligned
      % INSTANTANEOUS FIRING RATE (IFR; spike rate estimate) average plots
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
            for i = 1:numel(obj)
               batchProbeAvgIFRplot(obj(i),trialType,tPre,tPost);
            end
            return;
         end
         
         probeAvgIFRplot(obj.Children,trialType,tPre,tPost,true);
      end
      
      % Batch export LFP coherence plots
      function batchLFPcoherence(obj,trialType,tPre,tPost)
      %BATCHLFPCOHERENCE Batch export LFP coherence plots
      %
      % Batch export (save and close) TRIAL- or STIMULUS-aligned COHERENCE
      % plots for LFP-LFP cross-channel COHERENCE.
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
            for i = 1:numel(obj)
               batchLFPcoherence(obj(i),trialType,tPre,tPost);
            end
            return;
         end
         
         probeLFPcoherence(obj.Children,trialType,tPre,tPost);
      end
      
      % Return `solBlock` child according to Index
      function solBlockObj = Block(obj,Index)
      %BLOCK Method to return `solBlock` according to _INDEX (folder ID)
      %
      %  solBlockObj = obj.Block(Index);
      %
      %  Inputs
      %     obj   - `solRat` object
      %     Index - from Block folder name: (RYY-###_2019_MM_DD_INDEX)
      %
      %  Output
      %     solBlockObj - `solBlock` object according to Index
      
         % Add error parsing for indexing
         if Index > (numel(obj.Children)+1)
            error('Index (%d) is too large for %s.',Index,obj.Name);
         end
         if Index < 0
            error('Index (%d) cannot be negative.',Index);
         end
         if isnan(Index)
            error('Index is NaN. Did something else go wrong?');
         end
         
         idx = find([obj.Children.Index] == Index,1,'first');
         solBlockObj = obj.Children(idx);
      end
      
      % Returns **master** data table for convenient export of dataset
      function masterTable = makeTables(obj)
      %MAKETABLES Returns master data table for convenient data export
      %
      %  masterTable = obj.makeTables;
      %  masterTable = makeTables(objArray);
      %
      %  Inputs
      %     obj - Scalar or Array of `solRat` objects
      %  
      %  Output
      %     masterTable - Table with the following variable names...
      %           (to be added)
      
      % % Load in mat file created in main.m of solRat (now is `obj`)
      % load('R19-227.mat')
      % Instead, check if its scalar or array and iterate on array if so:
      if ~isscalar(obj)
         masterTable = table.empty; % Create empty data table to append
         for iRat = 1:numel(obj)
            % Note: we could pre-allocate `masterTable` but this isn't
            % really that much slower here and is a lot more convenient to
            % write for the time-being.
            masterTable = [masterTable; obj(iRat)]; %#ok<AGROW>
         end         
         return; % End "recursion"
      end

      % Start making the table
      trialID = obj.Children.Name;

      % Note that obj.Children can be an array. So this syntax works currently, but
      % only because there is a single Block in the example.

      %number of rows = number of channels * number of trials
      nChannels = length(obj.Children.Children);
      trialTypes = obj.Children.TrialType;
      nTrials = length(obj.Children.TrialType);
      nRows = nChannels * nTrials;
      RowID = strings([nRows 1]);

      alphabet = strcat('a':'z','A':'Z');

      for i = 1:nRows
          randstr = alphabet(randi(length(alphabet), 1, 10));
          RowID(i) = strcat("ROWID_",randstr);
      end

      % should group be a number? or should it say: "Solenoid","ICMS","ICMS+Solenoid"
      % 1 = evoked response of the solenoid only
      % 2 = evoked response of ICMS only
      % 3 = evoked response from the combination of solenoid and ICMS. 

      GroupID = repelem(trialTypes, 64);

      % %if you want it as a group name, not value do this
      % GroupStr = strings([nRows 1]);
      % 
      % for i = 1:length(GroupID)
      %     if GroupID(i) == 1
      %         GroupStr(i) = 'Solenoid';
      %     end
      %     if GroupID(i) == 2
      %         GroupStr(i) = 'ICMS';
      %     end
      %     if GroupID(i) == 3
      %         GroupStr(i) = 'Solenoid+ICMS';
      %     end
      % end

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

      % For any of the parts I've commented out, try moving those in as
      % methods of `solBlock` (the object comprising each array element of
      % `solRat` obj.Children array). That method should accept
      % obj.Children as a full array (see iterator used above).
      
      % % Commented part below has to change % %
      %   (Won't work when there are multiple Blocks for each Rat ) %
%       for i = 1:nChannels
%           depthArr(i) = obj.Children.Children(i,1).Depth;
%           hemisphereArr(i) = obj.Children.Children(i,1).Hemisphere;
%           impedenceArr(i) = obj.Children.Children(i,1).Impedance;
%           nameArr(i) = obj.Children.Children(i,1).Name;
%       end

      Depth = repmat(depthArr,nTrials,1);
      Hemisphere = repmat(hemisphereArr,nTrials,1);
      Impedance = repmat(impedenceArr,nTrials,1);
      Names = string(repmat(nameArr,nTrials,1));

      trialNumber = repelem(1:nTrials,nChannels)';
      % make the table 

      masterTable = table(TrialID, BlockID, RowID, AnimalID, GroupID, ...
          Group, Channel, trialNumber, ...
          Names, Hemisphere, Depth, Impedance);

      % % Commented part below has to change % %
      %   (Won't work when there are multiple Blocks for each Rat ) %
      
%       % get the Histogram (spikes; PETH) and LFP data timeseries
%       binCell = {nRows,1};
%       %for loop over the whole table
%       for iRow = 1:height(masterTable)
%           %first need to get which channel that row is
%           iChan = table2array(masterTable(iRow,'Channel'));
%           %get the binned spikes for that channel, allTrials is 118x500 double
%           % 118 --> Number of trials
%           % 500 --> Number of time bins (-500 : 500 ms; 2-ms bins)
%           allTrials = obj.Children.Children(iChan,1).getBinnedSpikes();
%           %get the specific trial in question using the trialNumber as index
%           %each cell in binCell should return a 1x500 double
%           binCell{iRow} = allTrials(table2array(masterTable(iRow,'trialNumber')),:);
%       end

      %have to some reason transpose it to get it to be nx1
      binCellt = binCell';

      %add it to the table
      masterTable.Spikes = binCellt;

      % ChannelID and ProbeID
      % this variable/section will need to be changed
      % unsure how these filenames correspond with each of the channels from
      % solRat object
      % is P1 Ch 0 always == channel 1?
      wav_sneo_folder = 'R19-227_2019_11_05_2_wav-sneo_CAR_Spikes'; 

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
          for iRow = 1:height(masterTable)
              %get the channel of that row
              iChan = table2array(masterTable(iRow,'Channel'));
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
      masterTable.ChannelID = chTable;
      masterTable.ProbeID = probeTable;

      % move the variable around so its next to the other channel stuff
      masterTable = movevars(masterTable,'ProbeID','After','Channel');
      masterTable = movevars(masterTable,'ChannelID','After','ProbeID');

      % Load in the _DS mat files and parse them using timestamps

      % Default PETH parameters
      tpre = -0.250;
      tpost = 0.750;
      % fs is 1000 for the _DS data
      timeStamps = obj.Children.Trials;

      %using fs and the timeStamps create a nTrials x 2 array of indices 
      % first value is the start of that 1s window (in samples), second is end
      % these indices can then be used to index into mat files and grab data

      windowInd = zeros(nTrials, 2);

      for i = 1:nTrials
          % should I round up or down? 
          % the boundary is never on a whole number index
          % right now round down on the beginning, and round up on the end
          % tpre is a negative number, so add it 
          windowInd(i,1) = floor(timeStamps(i)*fs+(tpre*fs));
          windowInd(i,2) = ceil(timeStamps(i)*fs+(tpost*fs));
      end

      %now use windowInd to access the mat files and parse the data
      %using cells because some of the windows be off by 1 due to rounding
      lfp = cell(nRows,1);
      % loop through the .mat files in _DS

      DS_folder = 'R19-227_2019_11_05_2_DS'; 

      %gets all mat files only
      matFiles = dir(fullfile(DS_folder,'*.mat')); 
      %iterate through all the files
      for i = 1:length(matFiles)
        fileName = matFiles(i).name;
        load(fileName);
        fileSplit = split(fileName, '_');
        probe = fileSplit(end-2);
        %have to get rid of the .mat on this
        chSplit = split(fileSplit(end), '.');
        ch = str2double(chSplit(end-1));

        % find the rows where you have that channel and probe
        % there might be a faster way to do this? not sure
        % iterate through all rows
        for iRow = 1:height(masterTable)
            % if the channel is correct
            chI = table2array(masterTable(iRow,'ChannelID'));
            if chI == ch
                % if the probe is correct
                if strcmp(table2array(masterTable(iRow,'ProbeID')), cell2mat(probe))

                    % grab the indicies we parsed earlier and get that data
                    ind = table2array(masterTable(iRow,'trialNumber'));
                    t = windowInd(ind,:);
                    lfp{iRow} = data(t(1):t(2));
                end
            end
        end

      end

      % add it to the table
      masterTable.LFP = lfp;
         
      end
      
      % Set stimulus times for each `solBlock` child
      function parseStimuliTimes(obj)
      %PARSESTIMULITIMES Set stimulus times for each `solBlock` child
      %
      %  parseStimuliTimes(obj);
      %
      % Get ICMS stimuli times for all BLOCKS (children) of this SOLRAT
      % object 
         
         % If called at "Rat" level, force parsing for all BLOCK times
         parseStimuliTimes(obj.Children,true);
      end
      
      % Set Layout of probes for each child `solBlock` of this `solRat`
      function setLayout(obj,L)
      %SETLAYOUT Set probe layout for all child Blocks of this Rat
      %
      %  setLayout(obj,L);
      %
      %  Inputs
      %     obj - `solRat` object
      %     L - Layout (see `cfg.default('L')`)
      %  
      %
      % Set the probe LAYOUT (channel spatial organization, where rows
      % indicate deeper sites and columns indicate mediolateral or
      % rostro-caudal span), for all BLOCKS (children) of this SOLRAT
      % object
         if nargin < 2
            L = cfg.default('L');
         end
         obj.Layout = L;
         setLayout(obj.Children,L);
      end
      
      % Set figure browser object
      function setFB(obj,figBrowserObj)
         if numel(obj) > 1
            for i = 1:numel(obj)
               obj(i).setFB(figBrowserObj);
            end
            return;
         end
         
         if ~isa(figBrowserObj,'figBrowser')
            error('figBrowserObj must be of class FIGBROWSER');
         end
         obj.fbrowser = figBrowserObj;
         
      end
   end
   
   % Class Constructor & Overloaded methods
   methods
      % Class constructor
      function obj = solRat(folder)
      %SOLRAT Class constructor for `solRat` organization object
      %
      %  obj = solRat(folder);
      
         % Get folder location
         if nargin < 1 % If no input
            clc;
            [obj.folder,flag] = utils.getPathTo('Select RAT folder');
            if ~flag
               obj = [];
               return;
            end
         elseif ischar(folder) % "Standard" input
            obj.folder = folder;
         elseif iscell(folder) % Can take cell array of folders
            nRat = numel(folder);
            obj = solRat(nRat);
            for ii = 1:nRat
               obj(ii) = solRat(folder{ii});
            end
            return;
         elseif isnumeric(folder) && isscalar(folder) % Initialize array
            nRat = folder;
            obj = repmat(obj,nRat,1);
            return;
         end
         
         % Get name of rat
         obj.Name = obj.parseName;
         
         % Initialize blocks
         obj.Children = obj.initChildBlocks;
      end
      
      % Overload of built-in `openfig` method
      function openfig(obj)
      %OPENFIG Overloaded `openfig` method to view figures
      %
      % OVERLOADED METHOD for OPENFIG - lets you view rat object figures
      % more easily.
         if isempty(obj(1).fbrowser)
            obj(1).fbrowser = figBrowser(obj);
         else
            open(obj(1).fbrowser);
         end
      end
      
      % Overload of built-in `save` method
      function save(obj)
      %SAVE Overloaded method for saving `rat` object
      %
      % OVERLOADED METHOD: save(obj);
      % Saves in current folder as [obj.Name '.mat'], with obj named as
      % variable 'r'
      
         % Handle object arrays
         if numel(obj) > 1
            for i = 1:numel(obj)
               save(obj(i));
            end
            return;
         end
         
         savetic = tic; % Start timing save
         
         % Notify command window of which SOLRAT is being saved
         fname = fullfile(pwd,[obj.Name '.mat']);
         fprintf(1,...
            'Saving %s (as %s.mat): in progress...\n',...
            obj.Name,obj.Name);

         % Save object as variable 'r' for consistency elsewhere
         r = obj;
         save(fname,'r','-v7.3');
         
         % Update command window
         backspace_str = repmat('\b',1,15);
         savetoc = round(toc(savetic));
         fprintf(1,...
            [backspace_str 'successful!\n-->\t(%g sec elapsed)\n\n'],...
            savetoc);
      end
   end
   
   % Private "helper" methods (for initialization, etc.)
   methods (Access = private)
      % Initialize objects for recordings associated with this `solRat`
      function Children = initChildBlocks(obj)
      %INITCHILDBLOCKS Initialize all child `solBlock` objects
      %
      %  Children = obj.initChildBlocks;
      %
      %  Inputs
      %     obj - `solRat` object or array of `solRat` objects
      %
      %  Output
      %     Children - Scalar or array `solBlock` for all child Blocks of
      %                 rat in input scalar or array
      %
      % Initializes CHILDREN (SOLBLOCK class objects), each of which is a
      % separate recording (experiment) for this SOLRAT object
      
         if numel(obj) > 1
            Children = [];
            for i = 1:numel(obj)
               Children = [Children; initChildBlocks(obj(i))]; %#ok<AGROW>
            end
            return;
         end
         F = dir(fullfile(obj.folder,[obj.Name '*']));
         Children = solBlock(numel(F)); % Initialize array
         for iF = 1:numel(F)
            Children(iF) = solBlock(obj,fullfile(F(iF).folder,F(iF).name));
         end
      end
      
      % Parse RAT name from folder (path) hierarchical structure
      function Name = parseName(obj)
      %PARSENAME Parse string of rat from folder structure
      %
      %  Name = obj.parseName;
      %
      %  Inputs
      %     obj - `solRat` or array of `solRat` objects
      %
      %  Output
      %     Name - char array or if `solRat` is array, then this is
      %              returned as cell array
      
         if numel(obj) > 1
            Name = string.empty;
            for i = 1:numel(obj)
               Name = [Name; obj(i).parseName]; %#ok<AGROW>
            end
            return;
         end
         name = strsplit(obj.folder,filesep);
         Name = string(name{end});
      end
   end
   
   % Static "helper" method for retrieving defaults
   methods (Static = true)
      % Return defaults associated with `solRat`
      function varargout = getDefault(varargin)
      %GETDEFAULT Return defaults for parameters associated with `solRat`
      %
      %  varargout = solRat.getDefault(varargin);
      %  e.g.
      %     param = solRat.getDefault('paramName');
      %     [p1,...,pk] = solRat.getDefault('p1Name',...,'pkName');
      %
      %  Inputs
      %     varargin - Any of the parameter fields in the struct delineated
      %                 in `cfg.default`
      %
      %  Wrapper function to get variable number of default fields .
      %
      %  See Also: cfg.default
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
   
end