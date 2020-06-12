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
out.path = 'P:\Rat\BilateralReach\Solenoid Experiments';
out.excel = 'Reach-Scoring.xlsx';
%put the list of rat names ex: MM-T1, order matches namingValue
out.namingKey ={'MM-S1';'MM-S2';'MM-T1';'MM-T2';'MM-U1';'MM-U2';'MM-W1';'MM-W2'}; 
%put the list of their animal ID ex R19-226, order matches namingKey
out.namingValue = {'R19-224';'R19-225';'R19-226';'R19-227';'R19-230';'R19-231';'R19-232';'R19-233'}; 
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

% Probe depth parameters
out.offset =  -50;
out.spacing = -100;
out.nshank = 4;
out.depth = -500;

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
               'ID','',...
               'Type','',...
               'Time',[],...
               'Number',[],...
               'ICMS_Onset',[],...
               'ICMS_Channel',[],...
               'Solenoid_Onset',[],...
               'Solenoid_Offset',[]);

% Default figure position
out.figpos = [0.15 0.15 0.3 0.3];
out.figscl = 0.4; % how much to move across screen
out.barcols = {[0.8 0.2 0.2];[0.2 0.2 0.8]};

% Default PETH parameters
out.tpre = -0.250;
out.tpost = 0.750;
out.binwidth = 0.002;
out.ylimit = [0 50];
out.xlimit = [-250 750];

% Rate estimation parameters
out.rate.w = 20; % kernel size (ms)
out.rate.kernel = 'pg'; % pseudo-gaussian kernel (can be 'rect' or 'tri')

% Default LFP raw average trace parameters
out.ds.ylimit = [-1500 1500];
out.ds.xlimit = [-250 750];
out.ds.col = {[0.8 0.2 0.2]; [0.2 0.2 0.8]};
out.ds.lw = 1.75;
out.fs_d = 1000;

% Default IFR average trace parameters
out.ifr.ylimit = [-4 4];
out.ifr.xlimit = [-250 750];
out.ifr.col = {[0.8 0.2 0.2]; [0.2 0.2 0.8]};
out.ifr.lw = 1.75;

% For CYCLE setup, parsing parameters
out.analog_thresh = 0.02;     % Analog threshold for LOW to HIGH value
out.trial_duration = 1;       % Trial duration (seconds)
out.do_rate_estimate = true;  % Estimate rates (if not present)? [CAN BE LONG]
out.probe_a_loc = 'RFA'; % depends on recording block
out.probe_b_loc = 'S1';  % depends on recording block
out.trial_high_duration = 500; % ms (same for all recordings in CYCLE setup)
out.fig_type_for_browser = 'Probe-Plots';

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