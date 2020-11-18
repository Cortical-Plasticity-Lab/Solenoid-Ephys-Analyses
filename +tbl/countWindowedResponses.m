function [N,BinomialSize] = countWindowedResponses(tPeak,tStart,tStop)
%COUNTWINDOWEDRESPONSES Count the number of response peaks in a given window.
%
%  N = tbl.countWindowedResponses(ampTime,tStart,tStop);
%  [N,BinomialSize] = tbl.countWindowedResponses(tPeak,tStart,tStop);
%
% Inputs
%  tPeak    - See `C` from `new_analysis.m`; ampTime is nPeaks x nObs array
%              where each value is either NaN (if no peak) or the (ordered
%              from largest amplitude peak on left to smallest on right) 
%              time of occurrence (seconds) of the `nPeaks` 
%              largest spike peaks.
%              * Note: this will probably be `C.ampTime - X`, where X is
%                 the offset of the stimulus that we would like to count
%                 peaks in response to (either ICMS or Solenoid onset).
%  tStart - Window "start" time (seconds)
%  tStop  - Window "stop" time (seconds)
%
%     Peaks are counted according to the inequality:
%        tStart <= tPeak < tStop
%
% Output
%  N            - Number of response peaks within that time window
%  BinomialSize - Vector that is `nObs` by 1, which is just the value of
%                    `nPeaks` (typically: 5) indicating the maximum number
%                    of peaks that could fall within that time range.
%
% See also: tbl, new_analysis.m, run_stats.m
%           analyze, analyze.meanSpikesPerChannel

N = sum(tPeak >= tStart & tPeak < tStop,2);

if nargout > 1
   nPeaks = size(tPeak,2);
   BinomialSize = ones(size(N)).*(nPeaks + 1);
end

end