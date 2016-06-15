function [flat_table] = flattenTable(data)
% FLATTENTABLE Converts table with structs as columns to a flat
%   representation where all struct fields are columns in the table
%
% Usage:
%   flat_data = flattenTable(original_data) flattens the original data and
%     returns the resulting table

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

col_types = varfun(@isstruct, data, 'output', 'uniform');
flat_table = data(:, ~col_types);

for col_idx = 1:numel(data.Properties.VariableNames)
  if(col_types(col_idx) == 1)
    col = table2array(data(:, col_idx));
    col = struct2table(col);
    col = flattenTable(col);
    
    for new_idx = 1:numel(col.Properties.VariableNames)
      col.Properties.VariableNames{new_idx} = strcat(data.Properties.VariableNames{col_idx}, '_', col.Properties.VariableNames{new_idx});
    end
    
    flat_table = [flat_table, col];
  end
end

end