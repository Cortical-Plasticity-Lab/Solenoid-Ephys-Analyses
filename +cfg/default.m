function varargout = default(varargin)
%DEFAULT  Return defaults struct or a single field of struct
%
%  params = defaults.files();
%     * This format returns full struct of parameters.
%     e.g.
%     >> params.var1 == 'something'; params.var2 == 'somethingelse'; ...
%
%  [var1,var2,...] = defaults.files('var1Name','var2Name',...);
%     * This format returns as many output arguments as input arguments, so
%        you can select to return variables for only the desired variables
%        (just up to preference).
%
%
% By: Max Murphy  v1.0  2019-08-06  Original version (R2017a)
%                 v1.1  2019-11-09  Changed input/output parsing
%                 v1.2  2020-05-18  Fixed format to match other projects

% Change file path stuff here
out = struct;
out.repos = struct('Utilities','D:\MATLAB\Projects\Utilities');
out.path = "P:\Rat\BilateralReach\Solenoid Experiments";
out.rats = [ ...
   "R19-224"; ...
   "R19-226"; ...
   "R19-227"; ...
   "R19-230"; ...
   "R19-231"; ...
   "R19-232"; ...
   "R19-234";
   ];
out.exported_database_table__local = "Solenoid-Table__5-ms.mat";
out.exported_database_table__remote = fullfile(out.path,...
   out.exported_database_table__local);
out.excel = "Reach-Scoring.xlsx";
out.site_location_table = "Probe-Info.xlsx";
out.solenoid_location_table = "Solenoid-Info.xlsx";
out.icms_file = "ICMS-Info.xlsx";
out.transform = @(y)atan(pi*y - pi/2); % Transform for LME predicted output
%put the list of rat names ex: MM-T1, order matches namingValue
out.namingKey ={'MM-S1';'MM-S2';'MM-T1';'MM-T2';'MM-U1';'MM-U2';'MM-W1';'MM-W2';'MM-V1'}; 
%put the list of their animal ID ex R19-226, order matches namingKey
out.namingValue = {'R19-224';'R19-225';'R19-226';'R19-227';'R19-230';'R19-231';'R19-232';'R19-233';'R19-234'}; 
out.subf = struct('raw','_RawData',...
                  'filt','_FilteredCAR',...
                  'ds','_DS',...
                  'rate','_IFR',...
                  'sf_coh','_Spike-Field-Coherence',...
                  'coh','_Cross-Spectral-Coherence',...
                  'spikes','_wav-sneo_CAR_Spikes',...
                  'dig','_Digital',...
                  'stim','STIM_DATA',...
                  'figs','_Figures',...
                  'peth','PETH',...
                  'rasterplots','Rasters',...
                  'probeplots','Probe-Plots',...
                  'lfpcoh','LFP-Coherence');
               
out.id = struct('trig','_DIG_trigIn.mat',...
                ... 'trig','_ANA_trialIn.mat',...
                ... 'sol','_DIG_solenoidOut.mat',...
                'sol','_DIG_solenoidIn.mat',...
                'trial','_ANA_trialIn.mat',...
                'iso','_ANA_isoIn.mat',...
                'icms','_DIG_icmsIn.mat',...
                'stim_info','_StimInfo.mat',...
                'info','_RawWave_Info.mat',...
                'raw','Raw_P',...
                'filt','FiltCAR_P',...
                'ds','DS_P',...
                'rate','Rate',...
                'sf_coh','SF-Coh_P',...
                'coh','Coh',...
                'spikes','ptrain_P',...
                'stim','STIM_P',...
                'gen','_GenInfo.mat',...
                'peth','_PETH',...
                'probepeth','_Probe-PETH',...
                'rasterplots','Raster',...
                'lfpcoh','_Probe-LFP-Coherence',...
                'probeavglfp','_Probe-Avg-LFP',...
                'probeavgifr','_Probe-Avg-IFR');

% Change layout stuff here
out.L = {  '019','021','000','029',...
           '009','016','005','003',...
           '014','010','001','004',... % Layout (L)
           '013','011','026','002',... % 32-channel
           '012','023','031','028',... % NeuroNexus A4x8
           '018','015','007','006',...
           '017','008','025','027',...
           '022','020','024','030'};
        
% This was for only a few pilot recordings that used 16-channel arrays
% out.L = {'008','011','006','001',... % Layout (L)
%          '009','014','003','000',... % 16-channel 
%          '015','012','002','005',... % NeuroNexus A4x4
%          '013','010','004','007'};

% ICMS suppression parameters
out.pre_stim_suppress = 0.010;  % seconds
out.post_stim_suppress = 0.015; % seconds

% Probe depth parameters
out.offset =  50;  % (microns from bottom channel to tip)
out.spacing = 100; % (microns between channels on a shank)
out.nshank = 4;            % # of shanks on the electrode
out.nchannelpershank = 8;  % # of channels on each shank
out.depth = -500;
out.shankspacing = 400; % microns, distance between array shanks
out.depthkey = struct('A',1600,'B',1300); % A : RFA -- 1600 microns; B : S1 -- 1300 microns
out.thetakey = struct('A',0,'B',45);      % degrees (rotated from midline; + is clockwise)
out.areakey = struct('A',"RFA",'B',"S1"); % areas
out.mlkey = struct('A',2.5,'B', 3.5); % (mm) Lateral from bregma
out.apkey = struct('A',2.5,'B',-0.5); % (mm) Anterior (rostral) from bregma
out.orientationkey = struct('A',"Caudal",'B',"Rostral");

% Defaults for graphics things
out.color_order = [0.0 0.0 0.0; ...
                   0.1 0.1 0.9; ...
                   0.9 0.1 0.1; ...
                   0.8 0.0 0.8; ...
                   0.4 0.4 0.4; ...
                   0.5 0.6 0.0; ...
                   0.0 0.7 0.7];
out.figparams = {'Color','w','Units','Normalized','Position',[0.2 0.2 0.5 0.5]};
out.axparams = {'NextPlot','add','XColor','k','YColor','k','LineWidth',1.25,'ColorOrder',out.color_order};
out.scatterparams = {'Marker','o','MarkerFaceColor','flat','MarkerFaceAlpha',0.75};
out.fontparams = {'FontName','Arial','Color','k'};

% Trial data struct
out.init_trial_data = struct(...
               'TrialID',"",...
               'Type',"",...
               'Time',[],...
               'Number',[],...
               'ICMS_Onset',[],...
               'ICMS_Channel',[],...
               'Solenoid_Onset',[],...
               'Solenoid_Offset',[],...
               'Solenoid_Target',"",...
               'Solenoid_Paw',"",...
               'Solenoid_Abbrev',"");

% Default figure position
out.figpos = [0.15 0.15 0.3 0.3];
out.figscl = 0.4; % how much to move across screen
out.barcols = {[0.8 0.2 0.2];[0.2 0.2 0.8]};

% Default PETH parameters
out.tpre = -0.250;
out.tpost = 0.500;    % Decrease (750-ms to 500-ms: 2020-07-23)
out.binwidth = 0.005; % Increase (2-ms to 5-ms: 2020-07-23)
out.ylimit = [0 50];
out.xlimit = [-250 500];
out.labelsindex = 23; % Index of channel to add labels to in subplot array
out.indicator_pct = 0.9; % % of max. height for superimposing timing indicator lines

% Rate estimation parameters
out.rate.w = 20; % kernel size (ms)
out.rate.kernel = 'pg'; % pseudo-gaussian kernel (can be 'rect' or 'tri')

% Default LFP raw average trace parameters
out.ds.ylimit = [-1500 1500];
out.ds.xlimit = [-250 500];
out.ds.col = {[0.8 0.2 0.2]; [0.2 0.2 0.8]};
out.ds.lw = 1.75;
out.fs_d = 1000;
out.clip_bin_counts = false; % Do not clip bin counts to one if false

% Default IFR average trace parameters
out.ifr.ylimit = [-4 4];
out.ifr.xlimit = [-250 500];
out.ifr.col = {[0.8 0.2 0.2]; [0.2 0.2 0.8]};
out.ifr.lw = 1.75;

% For CYCLE setup, parsing parameters
out.sol_onset_phys_delay = 0.004; % Physical delay (seconds) between HIGH and solenoid striking paw
out.analog_thresh = 0.02;     % Analog threshold for LOW to HIGH value
out.trial_duration = 1;       % Trial duration (seconds)
out.do_rate_estimate = true;  % Estimate rates (if not present)? [CAN BE LONG]
out.probe_a_loc = 'RFA'; % depends on recording block
out.probe_b_loc = 'S1';  % depends on recording block
out.trial_high_duration = 500; % ms (same for all recordings in CYCLE setup)
out.fig_type_for_browser = 'Probe-Plots';

% (main experiment) Lists for making categorical variables (reduce size)
out.all_blocks = ...
["R19-224_2019_11_04_0";
"R19-224_2019_11_04_1";
"R19-224_2019_11_04_2";
"R19-224_2019_11_04_3";
"R19-226_2019_11_05_0";
"R19-226_2019_11_05_1";
"R19-226_2019_11_05_2";
"R19-226_2019_11_05_3";
"R19-227_2019_11_05_0";
"R19-227_2019_11_05_1";
"R19-227_2019_11_05_2";
"R19-227_2019_11_05_3";
"R19-227_2019_11_05_4";
"R19-227_2019_11_05_5";
"R19-227_2019_11_05_6";
"R19-230_2019_11_06_0";
"R19-230_2019_11_06_1";
"R19-230_2019_11_06_2";
"R19-230_2019_11_06_3";
"R19-230_2019_11_06_4";
"R19-230_2019_11_06_5";
"R19-231_2019_11_06_0";
"R19-231_2019_11_06_1";
"R19-231_2019_11_06_2";
"R19-231_2019_11_06_3";
"R19-231_2019_11_06_4";
"R19-231_2019_11_06_5";
"R19-231_2019_11_06_6";
"R19-232_2019_11_07_0";
"R19-232_2019_11_07_1";
"R19-232_2019_11_07_2";
"R19-232_2019_11_07_3";
"R19-232_2019_11_07_4";
"R19-232_2019_11_07_5";
"R19-234_2019_11_07_0";
"R19-234_2019_11_07_1";
"R19-234_2019_11_07_2";
"R19-234_2019_11_07_3";
"R19-234_2019_11_07_4";
"R19-234_2019_11_07_5";
"R19-234_2019_11_07_6";
"R19-234_2019_11_07_7"];
out.all_abbr = ... % All possible abbreviations for TAG (see Solenoid-Info.xlsx)
   ["U";
    "WR";
    "PAW";
    "D1";
    "D1P";
    "D1K";
    "D2";
    "D2P";
    "D2K";
    "D3";
    "D3P";
    "D3K";
    "D4";
    "D4P";
    "D4K";
    "D5";
    "D5P";
    "D5K";
    "PLM";
    "DFL";
    "PFL"];
out.all_tgt= ... % All possible "generic" target options (see Solenoid-Info.xlsx, Target column)
   ["Forelimb";
    "Digit"; 
    "Knuckle";
    "Wrist";
    "Paw";
    "Palm"];

% Parse output (don't change this part)
if nargin < 1
   varargout = {out};   
else
   F = fieldnames(out);   
   if (nargout == 1) && (numel(varargin) > 1)
      varargout{1} = struct;
      for iV = 1:numel(varargin)
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{1}.(F{idx}) = out.(F{idx});
         end
      end
   elseif nargout > 0
      varargout = cell(1,nargout);
      for iV = 1:nargout
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{iV} = out.(F{idx});
         end
      end
   else % Otherwise no output args requested
      varargout = {};
      for iV = 1:nargin
         idx = strcmpi(F,varargin{iV});
         if sum(idx) == 1
            fprintf('<strong>%s</strong>:',F{idx});
            disp(out.(F{idx}));
         end
      end
      clear varargout; % Suppress output
   end
end
end