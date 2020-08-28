function T = addSlicing(T,slice_var,slice_val)
%ADDSLICING  Add 'Slicing' field to UserData struct table property or append to existing 'Slicing' list
%
% T = tbl.addSlicing(T,slice_var,slice_val);
%
% Inputs
%  T         - Data table
%  slice_var - Variable used to apply `analyze.slice` to table
%  slice_val - Values that were retained within `slice_var`
%
% Output
%  T         - Same as input but with updated 'Slicing' field of 
%                 UserData struct property

if ~isstruct(T.Properties.UserData)
   T.Properties.UserData = struct;
end

if isfield(T.Properties.UserData,'Slicing')
   T.Properties.UserData.Slicing(end+1,1) = addValue(slice_var,slice_val);
else
   T.Properties.UserData.Slicing = addValue(slice_var,slice_val);
end

   function slice_array = addValue(sVar,sVal)
      %ADDVALUE Add value to slice filter array struct
      %
      %  slice_array = addValue(sVar,sVal);
      
      slice_array = struct;
      % Do this way to prevent inadvertant creation of struct array
      slice_array.Variable = sVar;
      slice_array.Value = sVal;
   end

end