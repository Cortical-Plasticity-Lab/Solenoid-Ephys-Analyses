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
         %     masterTable - Table with the following variables:
         %        * `RowID`    - Unique "key" for each row (trial)
         %        * `AnimalID` - Name of rat
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
         %        * `DeficitSeverity` - Severity of animal's deficit, parsed
         %                              from animal behavioral record.
         %        * `Spikes` - Binned spike counts relative to alignment for a
         %                       single channel.
         %        * `LFP`    - LFP time-series relative to alignment for a
         %                       single channel.
         %        * `Notes` - Most-likely empty, but allows manual input of
         %                    notes or maybe a notes struct? Basically
         %                    something that lets you manually add "tags" to
         %                    the data rows.
         
         % Check if its scalar or array and iterate on array if so:
         if ~isscalar(obj)
            masterTable = table.empty; % Create empty data table to append
            for iRat = 1:numel(obj)
               % Note: we could pre-allocate `masterTable` but this isn't
               % really that much slower here and is a lot more convenient to
               % write for the time-being.
               masterTable = [masterTable; makeTables(obj(iRat))]; %#ok<AGROW>
            end
            return; % End "recursion"
         end
         
         % Need to parse the following variables from Rat:
         %  * `RowID`            (at very end of table-making process)
         %  * `GroupID`    - Associated with Animal (see **Column K** of
         %                    `Reach-Scoring.xlsx`)
         %  * `AnimalID`   - From `obj.Name`
         %  * `DeficitSeverity` (or any other behaviorally-related metadata)
         %
         %  * The rest of the table comes from:
         %     `blockTable = makeTables(obj.Children);`
         %
         %  Strategy --
         %     1) Create `ratTable` in this method using data parsed from Rat
         %     2) Create `blockTable` using syntax above (within `makeTables`
         %           of `solBlock` it makes sense to reference a similar
         %           method of organization for `solChannel` objects)
         %     3) Replicate `ratTable` to same number of rows as `blockTable`
         %     4) Concatenate the two tables (horizontally) to create
         %        `masterTable`
         %        -> You can either add `RowID` after (3) or (4)
         
         % `deficitTable` contains `AnimalID`, `SurgID`, and `Group`
         deficitTable = parseDeficitSeverity(obj); % Empty method currently
         
         % Runs on each child Block of `solRat`:
         blockTable = makeTables(obj.Children);
         % Replicate `deficitTable` to match number of rows from Block
         nBlockRows = size(blockTable,1);
         ratTable = repmat(deficitTable,nBlockRows,1);
         
         % Concatenate tables
         masterTable = [ratTable, blockTable];
         
         % Add unique "ID" to each row
         masterTable.RowID = utils.makeKey(...
            nBlockRows,'unique',[strrep(obj.Name,'-','') '_']);
         
         % Move appended `RowID` to first variable:
         masterTable = masterTable(:,[end, 1:(end-1)]);
      end
      
      % Returns quantitative indicator of deficit severity [PLACEHOLDER]
      function [deficitTable,behaviorTable] = parseDeficitSeverity(obj)
         %PARSEDEFICITSEVERITY Return some indicator of deficit (behavior)
         %
         % deficitSeverity = parseDeficitSeverity(obj);
         %
         % Inputs
         %  obj - Scalar or array `solRat` object
         %
         % Output
         %  deficitSeverity - Quantitative indicator of behavioral deficit
         %     * TBD (see: Reach-Scoring.xlsx for data source)
         %      returns a row per each animal, containing percent sucess
         %      over each of the days, pre and post
         
         if ~isscalar(obj)
            deficitTable = table.empty;
            behaviorTable = table.empty;
            for i = 1:numel(obj)
               [tmpDeficit,tmpBehavior] = parseDeficitSeverity(obj(i));
               deficitTable = [deficitTable; tmpDeficit]; %#ok<AGROW>
               behaviorTable = [behaviorTable; tmpBehavior]; %#ok<AGROW>
            end
            return;
         end
         
         [SurgID,AnimalID] = solRat.getDefault('namingValue','namingKey');
         keyTable = table(SurgID,AnimalID);
         keyTable = keyTable(strcmpi(keyTable.SurgID,obj.Name),:);
         %          %solRat.getDefault()
         %          nameDict = containers.Map(...
         %             solRat.getDefault('namingValue'), ... % Names
         %             solRat.getDefault('namingKey'));      % Keys
         %load excel file
         excelTable = readtable(solRat.getDefault('excel'));
         % Parse experimenter-specific key (MM-[alphabet]#),
         %  using "unified" lab surgical number (RYY-###)
         %          ratID = obj.Name;
         %          ratName = nameDict(ratID);
         %
         %          ratDay = [];
         %          ratSuccess = [];
         %
         %          for iRow = 1:height(excelTable)
         %
         %              iName = table2array(excelTable(iRow,'Rat'));
         %              if cell2mat(iName) == ratName
         %                  ratDay = [ratDay; table2array(excelTable(iRow,'Day'))]; %#ok<AGROW>
         %                  ratSuccess = [ratSuccess; table2array(excelTable(iRow,'Percent_Success'))]; %#ok<AGROW>
         %              end
         %
         %          end
         %          ratProgress = [ratDay, ratSuccess];
         %          ratProgress = sortrows(ratProgress);
         %          deficitSeverity = table(convertCharsToStrings(ratID),{ratProgress});
         %          deficitSeverity.Properties.VariableNames = {'RatID' 'Success Progress'};
         
         % With tables, easiest to use `innerjoin` and `outerjoin` (and
         % faster usually)
         behaviorTable = outerjoin(keyTable,excelTable,...
            'Type','left',...
            'LeftKeys',{'AnimalID'},'RightKeys',{'Rat'},...
            'LeftVariables',{'SurgID','AnimalID'},...
            'RightVariables',{'Group','Day','Date',...
            'Door','First_Attempt_Successful',...
            'Multi_Reach_Successful','Failure_Or_Nose',...
            'Total','Total_Success','Percent_Success',...
            'Percent_First_Success'}); % Just so columns are ordered with "more categorical" on left
         
         % Example for deficitSeverity: average "pre" performance is used
         % to normalize trend, which is then fit using linear regression
         % with a sigmoid link
         deficitTable = behaviorTable(1,...
            {'SurgID','AnimalID','Group'});
         
         % Sums may be useful to indicate overall level of motivation for a
         % given animal (e.g. some were really eager and did more reaches
         % than others in general)
         deficitTable.Gross_Attempts = sum(behaviorTable.Total);
         deficitTable.Gross_Successful = sum(behaviorTable.Total_Success);
         deficitTable.Gross_First_Try_Success = sum(behaviorTable.First_Attempt_Successful);
         
         iBaseline  = behaviorTable.Day <= 0;
         iMeasure   = ~iBaseline;
         deficitTable.Pre_Success_Rate = mean(behaviorTable.Percent_Success(iBaseline));
         pct = behaviorTable.Percent_Success(iMeasure);
         day = behaviorTable.Day(iMeasure);
         pre = repelem(deficitTable.Pre_Success_Rate,numel(day),1);
         tbl = table(pct,day,pre);
         modelspec = 'pct ~ day + (1|pre)';
         lme = fitlme(tbl,modelspec);
         
         % Parse relevant parameters from the model
         deficitTable.Rsquared = lme.Rsquared.Adjusted;
         deficitTable.p = lme.Coefficients(2,6); % 'day', p-value column
         deficitTable.coeff = lme.Coefficients(2,2); % Coefficient for day
      end
      
      % Displays a graph of a rats behavior over time (pre and post op)
      function behaviorTraces(obj)
          % BEHAVIOR TRACES returns a graphic for behavior over time
          % behaviorTraces(obj)
          % Inputs
          %  obj - Scalar or array `solRat` object
          %
          % Output
          %  figures of the behavioral performance for each rat
          
          
          if ~isscalar(obj)       
            for i = 1:numel(obj)
               behaviorTraces(obj(i));
            end
            return;
         end
          
          [~,behavior] = obj.parseDeficitSeverity();
          
          figure
          scatter(behavior.Day,behavior.Percent_Success.*100)
          title(strcat(obj.Name ,' Percent Success Pre and Post Surgery'))
          xlabel('Day (Surgery = Day 0)')
          ylabel('Percent Success')
          xlim([-10 22])
          ylim([0 100])
          xline(0,'--r') %vertical line at day of surgery
         
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
         %  varargout = solRat.(varargin);
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