function C = estimateChannelResponse(T,fcn,inputVars,outputVar,varargin)
%ESTIMATECHANNELRESPONSE Apply custom response function on table to return CHANNEL-LEVEL averages taken across all trials of a given TYPE from a single BLOCK.
%
%  Note: 
%        This function will automatically split the table using the 
%        variables 'Type', 'BlockID' and 'ChannelID'; additional
%        "splitters" for increased granularity can be provided via
%        varargin. The contents of `fcn` are applied to a matrix or vector
%        (depending on what is specified via `inputVars`), and should
%        return a scalar output.
%
%  C = tbl.stats.estimateChannelResponse(T,fcn,inputVars,outputVar)
%  C = tbl.stats.estimateChannelResponse(T,fcn,inputVars,outputVar,'SplittingVar1','SplittingVar2',...)
%
%  Example:
%        ```
%           fcn = @(X){nanmean(X,1)}; % Returns trial-average time-series (as a cell)
%           inputVars = {'LFP'}; % Will use the 'LFP' variable in T
%           outputVar = 'LFP_mean'; % Output variable name
%           C = tbl.stats.estimateChannelResponse(T,fcn,inputVars,outputVar);
%        ```
%     -- Note --
%     The example above took ~15 seconds to run on my home desktop tower.
%
% Inputs
%  T           - Main database table ('Solenoid-Table__5-ms.mat' contents)
%  fcn         - Custom function handle to estimate channel-level response
%                 on inputs. Must return its output as a scalar; if output
%                 is non-scalar, then be sure it is "wrapped" in a cell so
%                 that it "looks" like a scalar to Matlab.
%  inputVars   - Names of input argument variables, given as string array
%                 or cell array of characters
%  outputVar   - Name of output argument variable: string or char array
%
% Output
%  C           - Condensed version of T, which contains response
%                 (outputVar) as one of the columns, with rows
%                 corresponding to unique channel/block/type combinations
%                 instead of individual trials.
%
% See also: tbl, tbl.stats

[G,C] = findgroups(T(:,[{'GroupID','SurgID','AnimalID','BlockID','BlockIndex','Type','Area','ChannelID','AP','ML','Depth','Channel','Stim_Ch','ICMS_Onset','Solenoid_Onset','Solenoid_Offset','Impedance','coeff','p'},varargin]));
tmp = splitapply(fcn,T(:,inputVars),G);
try
   tmp = cell2mat(tmp);
   C.(outputVar) = tmp;
   fprintf('\nConverted output <strong>(%s)</strong> from cell array to matrix format.\n',outputVar);
catch
   C.(outputVar) = tmp;
   fprintf('\nLeft output <strong>(%s)</strong> as cell array.\n',outputVar);
end
end

