function [modified_table] = combineTimes(original_table)
% COMBINETIMES Condenses results from standard ROS header into single time
%	Usage: 
%   modified = COMBINETIMES(data) Scans data for fields matching standard
%     header values. If they are found, append a column to the table which
%     is the combined seconds and nanoseconds field

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

% Copy the original data we will add to
modified_table = original_table;

% Field names matching the time fields in a standard ROS header
NSECS_FIELD_NAME = 'header_stamp_nsecs';
SECS_FIELD_NAME = 'header_stamp_secs';

% Find any columns that match the nanosecond field
nsec_fields = strncmp(...
  NSECS_FIELD_NAME, ...
  modified_table.Properties.VariableNames, ...
  length(NSECS_FIELD_NAME));

% Find any columns that match the seconds field
sec_fields = strncmp(...
  SECS_FIELD_NAME, ...
  modified_table.Properties.VariableNames, ...
  length(SECS_FIELD_NAME));

% Either we do not have a header, and the matches fail, or we should find
% exactly one column matching both our time fields.
assert((sum(nsec_fields) == 0) || (sum(nsec_fields) == 1));
assert((sum(sec_fields) == 0) || ...
  ((sum(sec_fields) == 1) && (sum(nsec_fields) == 1)));

% If we found the time fields in a standard header, combine them into one
% column
if(any(nsec_fields) && any(sec_fields))
  % Scale nanoseconds to seconds
  nsecs = double(table2array(modified_table(:, nsec_fields))) / 1e9;
  secs = double(table2array(modified_table(:, sec_fields)));
  % Store the output as seconds
  modified_table.header_times = secs + nsecs;
end

end