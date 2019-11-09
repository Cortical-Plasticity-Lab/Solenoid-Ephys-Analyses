function out = default(paramName)
%% DEFAULT  Return defaults struct or a single field of struct
%
%  out = cfg.DEFAULT(); % returns defaults struct
%  out = cfg.DEFAULT(paramName);  % returns only field specified by
%                                 % paramName
%
% By: Max Murphy  v1.0  2019-08-06  Original version (R2017a)
%                 v1.1  2019-11-09  Changed input/output parsing

%% Check input and parse cell arrays recursively (do not change)
if iscell(paramName)
   out = cell(size(paramName));
   for i = 1:numel(paramName)
      out{i} = cfg.default(paramName{i});
   end
   return;
end

%% CHANGE DEFAULTS HERE
out = struct;
out.path = 'P:\Rat\RegionSpecificity';

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
               
out.id = struct(... 'trig','_DIG_trigIn.mat',...
                'trig','_ANA_trialIn.mat',...
                ... 'sol','_DIG_solenoidOut.mat',...
                'iso','_ANA_isoIn.mat',...
                'icms','_ICMSIn.mat',...
                'sol','_DIG_solenoidIn.mat',...
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
 
out.L = {  '019','021','000','029',...
           '009','016','005','003',...
           '014','010','001','004',... % Layout (L)
           '013','011','026','002',... % 32-channel
           '012','023','031','028',... % NeuroNexus A4x8
           '018','015','007','006',...
           '017','008','025','027',...
           '022','020','024','030'};
        

% out.L = {'008','011','006','001',... % Layout (L)
%          '009','014','003','000',... % 16-channel 
%          '015','012','002','005',... % NeuroNexus A4x4
%          '013','010','004','007'};

% Probe depth parameters
out.offset =  -50;
out.spacing = -100;
out.nshank = 4;
out.depth = -500;

% Default figure position
out.figpos = [0.15 0.15 0.3 0.3];
out.figscl = 0.4; % how much to move across screen
out.barcols = {[0.8 0.2 0.2];[0.2 0.2 0.8]};

% Default PETH parameters
out.tpre = -0.250;
out.tpost = 0.750;
out.binwidth = 0.002;
out.ylimit = [0 200];
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
out.analog_thresh = 0.02; % Analog threshold for LOW to HIGH value

%%
if nargin > 0
   if isfield(out,paramName)
      out = out.(paramName);
   else
      fprintf(1,'Invalid field: %s\n->\tEmpty output returned.',paramName);
      out = [];
   end
end


end