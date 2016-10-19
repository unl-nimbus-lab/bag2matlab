function [converted_data] = py2Matlab(original_data)
% py2Matlab Convert Python objects to their Matlab equivalent
%	Usage:	py2Matlab(python_data) Converts data from a 
%           Python object to native Matlab representations.

%   Copyright (c) 2016 David Anthony
%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program; if not, write to the Free Software
%   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

  % Call the appropriate conversion routine for the given Python or Matlab
  % data type
  switch(class(original_data))
    case 'py.list'
      % Recursively call this function on all data in a list to convert
      % all Python objects in the list to Matlab types
      converted_data = cell(original_data);
      
      % If we were passed an empty list just return an empty array.
      % The conversion function below does not work on empty data and will
      % crash if it operates on an empty cell array.
      if(~isempty(converted_data))
        % We must call structfun on objects with non-scalar data types with
        % the UniformOutput argument set to false, or they don't convert
        % correctly.
        uniform_output = false;
        if(strcmp(class(converted_data{1}), 'py.int') || ...
          strcmp(class(converted_data{1}), 'py.long') || ...
          strcmp(class(converted_data{1}), 'py.array.array'))
          uniform_output = true;
        end
        converted_data = cellfun(@py2Matlab, converted_data, 'UniformOutput', uniform_output);
      else
        converted_data = [];
      end
      
    case 'py.dict'
      % Dictionaries can have Python data types in them, so recursively
      % convert them from Python types to Matlab types
      converted_data = struct(original_data);
      converted_data = structfun(@py2Matlab, converted_data, 'UniformOutput', false);
      
    case 'py.str'
      % Matlab has a bug where converting Python strings directly to Matlab
      % char arrays fails for ASCII values greater than 191. Casting to
      % uint8 first is a workaround to this problem.
      converted_data = char(uint8(original_data));
      % This assertion is a sanity check to make sure the workaround above
      % is still working and all of the data is converted.
      assert(numel(converted_data) == py.len(original_data));
      
    case 'py.tuple'
      converted_data = cell(original_data);
      
    case 'py.bytes'
      converted_data = uint8(original_data);
      
    case 'py.unicode'
      converted_data = char(original_data);
      
    case 'py.int'
      converted_data = int64(original_data);
      
    case 'py.long'
      converted_data = double(original_data);
      
    case 'py.array.array'
      converted_data = double(original_data);
      
    case 'double'
      converted_data = double(original_data);
                 
    case 'single'
      converted_data = single(original_data);
      
    case 'logical'
      converted_data = logical(original_data);
      
    case 'char'
      converted_data = char(original_data);
      
    case 'int8'
      converted_data = int8(original_data);
      
    case 'uint8'
      converted_data = uint8(original_data);
      
    case 'int16'
      converted_data = int16(original_data);
      
    case 'uint16'
      converted_data = uint16(original_data);
      
    case 'int32'
      converted_data = int32(original_data);
      
    case 'uint32'
      converted_data = uint32(original_data);
      
    case 'int64'
      converted_data = int64(original_data);
      
    case 'uint64'
      converted_data = uint64(original_data);
      
    otherwise
      % Encountered some data that we do not have an explicit handler for.
      % This may not be a problem, and indicates we hit some kind of
      % fundamental ROS data type. Trying converting each one of the object
      % members to a Matlab representation
      try
        % Iterate over every member of the object and try to convert it to
        % a Matlab data type.
        p = properties(original_data);
        converted_data = struct();
    
        % Initialize the struct field names
        for idx = 1:numel(p)
          converted_data.(p{idx}) = [];
        end
        
        % Use recursion to assign values to the fields
        for idx = 1:numel(p)
          converted_data.(p{idx}) = py2Matlab(original_data.(p{idx}));
        end
      catch
        error('Could not convert data of type: %s', class(original_data));
      end
  end
end