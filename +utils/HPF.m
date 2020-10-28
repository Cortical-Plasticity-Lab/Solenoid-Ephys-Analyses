function [out,state_out] = HPF(in,fc,fs,state_in)
%HPF   Software estimate of hardware single-pole state high-pass filter
%
%  out = utils.HPF(in);
%  out = utils.HPF(in,fc);
%  out = utils.HPF(in,fc,fs);
%  [out,state_out] = utils.HPF(in,fc,fs,state_in);
%
%  Example: If neural data sampled at 30 kSamples/sec, with desired cutoff
%           frequency of 300 Hz:
%
%           out = HPF(in,300,30000);
%
%  --------
%   INPUTS
%  --------
%     in    :     Input (raw) sample data.
%                 -> If array, then operates along ROWS (assumes that
%                       each COLUMN is a new time sample)
%
%     fc    :     Desired cutoff frequency (Hz)
%
%     fs    :     Sampling frequency (Hz)
%
%  state_in :     Use this if filtering "chunks" - the value given by
%                 state_out, which is used to initialize the state filter.
%                 Otherwise, the state filter is initialized to zero.
%
%  --------
%   OUTPUT
%  --------
%    out    :     High-pass filtered sample data. The filter is essentially
%                 a single-pole butterworth high-pass filter realized using
%                 a hidden "state" variable. 
%
%  state_out:     Final value of hidden "state" variable, which is useful
%                 if you are filtering data in "chunks" so that the
%                 subsequent chunk has the correct state initialization.
%
% Modified from original script provided by Intan Technologies.

% DEFAULTS
FS = 30000; % Default sample rate is 30 kSamples/sec
FC = 300;   % Default cutoff frequency

% PARSE INPUT
switch nargin
   case 1
      warning('No cutoff frequency given. Using default FC (%d Hz).',FC);
      fc = FC;
      warning('No sample rate specified. Using default FS (%d Hz).',FS);
      fs = FS;
      outLPF = zeros(size(in));
      state_in = zeros(size(in,1),1);
   case 2
      warning('No sample rate specified. Using default FS (%d Hz).',FS);
      fs = FS;
      outLPF = zeros(size(in));
      state_in = zeros(size(in,1),1);
   case 3
      outLPF = zeros(size(in));
      state_in = zeros(size(in,1),1);
   case 4
      outLPF = zeros(size(in));
      outLPF(:,1) = state_in;
   otherwise
      error('Too many inputs. Check syntax.');
end

if (size(in,1) > 1) && (size(in,2) > 1)
   out = nan(size(in));
   state_out = nan(size(in,1),1);
   for iRow = 1:size(in,1)
      [out(iRow,:),state_out(iRow)] = utils.HPF(in(iRow,:),fc,fs,state_in(iRow));
   end
   return;
end

% COMPUTE IIR FILTER COEFFICIENTS
A = exp(-(2*pi*fc)/fs);
B = 1 - A;

% USE LOOP TO RUN STATE FILTER
for i = 2:length(in)
    outLPF(i) = (B*in(i-1) + A*outLPF(i-1));
end

% RETURN FILTERED OUTPUT AND FINAL STATE
out = in - outLPF;
state_out = outLPF(end);

end
