function [converted_data] = py2Matlab(original_data)
% py2Matlab Convert Python objects to their Matlab equivalent
%	Usage:	py2Matlab(python_data) Converts data from a Python object to
%   native Matlab representations

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

  % Call the appropriate conversion routine for the given Python data type
  switch(class(original_data))
    case 'py.list'
      % Recursively call this function on all data in a list to convert
      % all Python objects in the list to Matlab types
      converted_data = cell(original_data);
      converted_data = cellfun(@py2Matlab, converted_data);
      
    case 'py.dict'
      % Dictionaries can have Python data types in them, so recursively
      % convert them from Python types to Matlab types
      converted_data = struct(original_data);
      converted_data = structfun(@py2Matlab, converted_data, 'UniformOutput', false);
      
    case 'py.str'
      converted_data = char(original_data);
      
    case 'py.tuple'
      converted_data = cell(original_data);
      
    case 'py.bytes'
      converted_data = uint8(original_data);
      
    case 'py.unicode'
      converted_data = char(original_data);
      
    case 'py.int'
      converted_data = double(original_data);
      
    case 'py.long'
      converted_data = double(original_data);
      
    case 'py.array.array'
      converted_data = double(original_data);
      
    otherwise
      % Encountered some data that we do not have an explicit handler for.
      % This probably is not problem and just means the data was part of a
      % dictionary or list we are automatically converting.
      converted_data = double(original_data);
  end
end