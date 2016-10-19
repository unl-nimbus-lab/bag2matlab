function [bag_data, topics_read] = bagReader(bag_file, varargin)
% BAGREADER Reads messages from a ROS bag file
%	Usage: 
%   [bag_data, topics_read] = BAGREADER(bag_file) returns a cell array of tables
%     of all the data in the bag 'bag_file'. Each cell item should be a
%     Matlab table, unless the data could not be converted to a table. In
%     that case, the data well be in a cell array. topics_read is a cell
%     array containing the names of the topics which correspond to the
%     entries in bag_data.
%
%     bag_file is the path to the bag file to analyze
%
%   [bag_data, topics_read] = BAGREADER(bag_file, topic_name) returns a
%     single table with only the data from 'topic_name' in it. 'topic_name'
%     is a string specifying a topic name.
%
%   [bag_data, topics_read] = BAGREADER(bag_file, topic_names) returns
%     tables corresponding to all of the topics in the topic_names cell array
%
%   BAGREADER(bag_file, topic_names, ...) Enables optional name/value pairs.
%     Possible options are as follows
%
%   'ros_root' -- A string specifying the location of the ROS distribution 
%     so the function can find the Python packages it depends on. This is 
%     useful if ROS is built from source and not installed in a standard 
%     location. If this pair is not specified, the function will check if 
%     the PYTHONPATH environment variable is set. If it is not, then it 
%     will scan /opt/ros and look for distribution folders there.
%
%   'combine_times' -- A logical value which if true makes the function 
%     search the message field names for a standard header. If one is 
%     found, combine the second and nanosecond fields in the header to make
%     a single combined time and add that to the results. Default value is 
%     true.
%
%   'min_idx' -- A positive integer or array that defines the 1-based indices to 
%     start reading messages from. Defaults to 1. Setting a larger values skips
%     over messages at the beginning of a bag file. The number of elements
%     in this argument must match the number of topics read from the bag
%     file. Pass in a NAN for an element to read all messages for that
%     topic.
%
%   'max_idx' -- A positive integer that is greater than min_idx. The
%     reader stops reading the bag file at this message index. min_idx and
%     max_idx are inclusive values, so specifying both of them results in
%     reading messages with indices between [min_idx, max_idx]. The number
%     of elements must match the number of topics read. Pass in a nan for an 
%     element to read all messages for that topic.
%
%   Example: Read all messages in flight.bag
%     [data, names] = bagReader('flight.bag');
%   Example: Read all messages published on /uav/pose in flight.bag
%     pose = bagReader('flight.bag', '/uav/pose');
%   Example: Read all messages published on /uav/pose and /uav/gps in flight.bag
%     [data, names] = bagReader('flight.bag', {'/uav/pose', '/uav/gps'});
%   Example: Read all messages from bag file if ROS is built in ~/ros_catkin-ws/devel
%     pose = bagReader('flight.bag', '/uav/pose', 'ros_root', '~/ros_catkin_ws/devel');
%   Example: Do not combine the seconds and nanoseconds fields in header messages
%     pose = bagReader('flight.bag', '/uav/pose', 'combine_times', false);
%   Example: Read the second 100 pose messages from the bag file
%     pose = bagReader('flight.bag', '/uav/pose', 'min_idx', 100, 'max_idx', 200);
%   Example: Read the second 100 pose messages from the bag file, and the
%     first 100 GPS messages
%     [data, names] = bagReader('flight.bag', {'/uav/pose', '/uav/gps'},
%       'min_idx', [100, 1], 'max_idx', [200, 100]);

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

%% Input parsing and validation
% Build an argument parser for reading the optional arguments
input_parser = inputParser;
% Set default values
default_ros_root = ''; % Do not guess where ROS is by default
default_time_combine = true; % Combine header time fields by default
default_min_msg_idx = []; % Do not bound the reading
default_max_msg_idx = []; % Do not bound the reading range
% Tell the parser about the possible inputs
addRequired(input_parser, 'bag_file', @ischar);
addOptional(input_parser, 'topic_names', {}, @(x)(ischar(x) || (iscell(x) && isvector(x)) || isempty(x)));
addParameter(input_parser, 'ros_root', default_ros_root, @ischar);
addParameter(input_parser, 'combine_times', default_time_combine, @islogical);
addParameter(input_parser, 'min_idx', default_min_msg_idx, @(x)(isempty(x) || (isnumeric(x) && (isvector(x) || isscalar(x)))));
addParameter(input_parser, 'max_idx', default_max_msg_idx, @(x)(isempty(x) || (isnumeric(x) && (isvector(x) || isscalar(x)))));

% Parse the inputs
parse(input_parser, bag_file, varargin{:});
topic_names = input_parser.Results.topic_names;
if(~isempty(topic_names))
  topics_read = topic_names;
end

% Check to make sure any directories the user passes in exist
assert(isempty(input_parser.Results.ros_root) || ...
  (exist(input_parser.Results.ros_root, 'dir') == 7), ...
  'Requested ROS root directory does not exist');

if(exist(input_parser.Results.bag_file, 'file') ~= 2)
  error('%s does not exist', input_parser.Results.bag_file);
end

% Check that we have the same number of min and max indices
assert(numel(input_parser.Results.min_idx) == numel(input_parser.Results.max_idx));

% If no topics were specified then we read all topics from the bag file. If
% multiple topics are specified, make sure they are all strings. If a
% single topic was specified, convert it to a cell array to make the future
% process the same for all options.
if(isempty(topic_names))
  topic_names = bagInfo(bag_file);
  topics_read = topic_names;
elseif(iscell(topic_names))
  for idx = 1:numel(topic_names)
    assert(ischar(topic_names{idx}));
  end
else
  topic_names = {topic_names};
end

% If minimum/maximum message indices are defined, they must be defined for
% all the topics to read from
assert(isempty(input_parser.Results.min_idx) || (numel(input_parser.Results.min_idx) == numel(topic_names)));

% Now check to make sure all min and max index pairs are valid. There are
% three conditions to check:
%   1. Either both are nans, or neither is a nan. nans indicate the ranges
%     are not checked when parsing the bag file, so either we don't check the
%     ranges, or we have a well defined interval to read from
%   2. If defined, the minimum index must be more than 0, because only
%     positive, one based indices are valid.
%   3. If defined, the maximum index must be greater than or equal to the
%     minimum index so that we have a well defined interval to read from.

for idx = 1:numel(input_parser.Results.min_idx)
  assert((isnan(input_parser.Results.min_idx(idx)) && isnan(input_parser.Results.max_idx(idx))) || ...
    (~isnan(input_parser.Results.min_idx(idx)) && ~isnan(input_parser.Results.max_idx(idx))));
  if(~isnan(input_parser.Results.min_idx(idx)))
    assert(input_parser.Results.min_idx(idx) > 0, ...
      'Minimum message index must be greater than 0');
    assert(input_parser.Results.max_idx(idx) >= input_parser.Results.min_idx(idx), ...
      'Maximum message index must be greater than or equal to the minimum index');    
  end
end

min_indices = input_parser.Results.min_idx;
max_indices = input_parser.Results.max_idx;

% If the min and max reading ranges are not defined by the user, set them
% to 1 and the maximum 64 bit integer number so that all messages in the
% bag file are read. This assumes there are less than 2^64 - 2 messages on
% any topic type in the bag file because of how we handle the conversion to
% a 0 based index
if(isempty(min_indices))
  min_indices = ones(numel(topic_names), 1);
  max_indices = ones(numel(topic_names), 1);
  max_indices(1:end) = intmax('int64');
else
  min_indices(isnan(min_indices)) = 1;
  max_indices(isnan(max_indices)) = intmax('int64'); 
end

% One last sanity check about having bounds for every topic we read from
assert(numel(topic_names) == numel(max_indices));
assert(numel(topic_names) == numel(min_indices));

% Initialize the output
bag_data = cell(numel(topic_names), 1);
for idx = 1:numel(topic_names)
  bag_data{idx} = table();
end

%% Python setup
% We need to import the helper function, which also depends on the
% underlying ROS Python modules working as well. Doing so depends on the
% environment being correctly configured. If Matlab launches from the
% terminal, it will pick up any ROS environment variables that were
% present, and everything should just work. However, many shortcuts to
% launching Matlab will not have the terminal environment, and thus Matlab
% will not know where the ROS distribution modules are at. In that case, we
% will attempt to find them for the user if the initial import fails.
setupEnv(input_parser.Results.ros_root);

%% Bag reading
% Read the data in the bag file. Convert the min/max indices to 0-indexed
% representation
for idx = 1:numel(topic_names)
  fprintf('Processing topic: %s\n', topic_names{idx});
  bag_data{idx} = py.matlab_bag_helper.read_bag(...
    bag_file, ...
    topic_names{idx}, ...
    min_indices(idx) - 1, ...
    max_indices(idx) - 1);
  % Convert the Python data to an array of structures
  bag_data{idx} = py2Matlab(bag_data{idx});
  % Check to see if we found any messages containing data
  if(~isempty(bag_data{idx}))
    % Occasionally this conversion fails because the ROS messages may have
    % field names that are Matlab keywords, and Matlab does not like having
    % structure fields that are keyword names. Wrap this in a try/catch
    % block to perform the conversion if possible. Otherwise, just keep the
    % data as a cell array.
    try
      % Now make the Matlab structures a table
      bag_data{idx} = struct2table(cell2mat(bag_data{idx}));
      % Flatten the table
      bag_data{idx} = flattenTable(bag_data{idx});
      % Now produce the combined time field if requested
      if(input_parser.Results.combine_times)
        bag_data{idx} = combineTimes(bag_data{idx});
      end
      
      % Store the topic name in the user data of the table
      bag_data{idx}.Properties.UserData = topic_names{idx};
    catch ME
      warning('Could not convert data on topic %s to table', topic_names{idx});
    end
  % Did not find any messages. Return an empty table
  else
    warning('Did not find any messages on topic %s in the bag file', topic_names{idx});
    bag_data{idx} = table();
  end
end

% Return a table instead of a one element cell array if only one topic was
% processed to make the output a little nicer
if(numel(bag_data) == 1)
  bag_data = bag_data{1};
end
end