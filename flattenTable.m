function [flat_table] = flattenTable(data)
% FLATTENTABLE Converts table with structs as columns to a flat
%   representation where all struct fields are columns in the table
%
% Usage:
%   flat_data = flattenTable(original_data) flattens the original data and
%     returns the resulting table. The flattening operation recursively 
%     converts all columns of structs into tables, where each table column
%     is a member of the struct.

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

% Determine which columns are structs
col_types = varfun(@isstruct, data, 'output', 'uniform');
% Initialize the output with all of the original columns that are not
% structs, because we will not mbe modifying them.
flat_table = data(:, ~col_types);

% Iterate over the input table and convert all columns with structs into a
% table representation
for col_idx = 1:size(data, 2)
  % Check if the column contains structs
  if(col_types(col_idx) == 1)
    % Converting a column of structs is a three part process. First convert
    % the column into an array of structs, then convert that array back to
    % a table. This 'unnests' the struct members as columns of table
    col = table2array(data(:, col_idx));
    col = struct2table(col);
    % Now we have a table where whose columns are members of the struct in
    % the original table. Recursively flatten these columns, in case we
    % have structs of structs.
    col = flattenTable(col);
    
    % Rename the column names with a prefix indicating the original column
    % name. This should guarantee all the column names are unique
    for new_idx = 1:numel(col.Properties.VariableNames)
      col.Properties.VariableNames{new_idx} = strcat(data.Properties.VariableNames{col_idx}, '_', col.Properties.VariableNames{new_idx});
    end
    
    % Concatentate the flattened table to our output
    flat_table = [flat_table, col];
  end
end

end