function T = addProcessing(T,processing_stage)
%ADDPROCESSING  Add 'Processing' field to UserData struct table property or append to existing 'Processing' list
%
% T = utils.addProcessing(T,processing_stage);
%
% Inputs
%  T - Data table
%  processing_stage - Char array to append to 'Processing' UserData struct field
%
% Output
%  T - Same as input but with updated 'Processing' field of UserData struct property

if ~isstruct(T.Properties.UserData)
   T.Properties.UserData = struct;
end

if isfield(T.Properties.UserData,'Processing')
   T.Properties.UserData.Processing = ...
      [T.Properties.UserData.Processing ' > ' processing_stage];
else
   T.Properties.UserData.Processing = processing_stage;
end

end