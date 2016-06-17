function [bag_data] = bagReader(bag_file, topic_name, varargin)
% BAGREADER Reads messages from a ROS bag file
%	Usage: 
%   bag_data = BAGREADER(bag_file, topic_name) returns a table of all 
%     the data published on the topic 'topic_name' in the bag 'bag_file'.
%
%     bag_file is the path to the bag file to analyze
%     topic_name is a string containing the topic name to read
%
%   BAGREADER(bag_file, topic_name, ...) Enables optional name/value pairs.
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
%   Example: pose = bagReader('flight.bag', '/uav/pose');
%   Example: pose = bagReader('flight.bag', '/uav/pose', 'ros_root', '~/ros_catkin_ws/devel');
%   ExamplE: pose = bagReader('flight.bag', '/uav/pose', 'combine_times', false);

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
default_ros_root = '';
default_time_combine = true;
% Tell the parser how the possible inputs
addRequired(input_parser, 'bag_file', @ischar);
addRequired(input_parser, 'topic_name', @ischar);
addParameter(input_parser, 'ros_root', default_ros_root, @ischar);
addParameter(input_parser, 'combine_times', default_time_combine, @islogical);

% Parse the inputs
parse(input_parser, bag_file, topic_name, varargin{:});

% Check to make sure any directories the user passes in exist
assert(isempty(input_parser.Results.ros_root) || ...
  (exist(input_parser.Results.ros_root, 'dir') == 7), ...
  'Requested ROS root directory does not exist');
assert(exist(input_parser.Results.bag_file, 'file') == 2, ...
  'Bag file does not exist');

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
% Read the data in the bag file
bag_data = py.matlab_bag_helper.read_bag(bag_file, topic_name);
% Convert the Python data to an array of structurs
bag_data = py2Matlab(bag_data);
% Check to see if we found any messages containing data
if(~isempty(bag_data))
  % Now make the Matlab structures a table
  bag_data = struct2table(bag_data);
  % Flatten the table
  bag_data = flattenTable(bag_data);
  % Now produce the combined time field if requested
  if(input_parser.Results.combine_times)
    bag_data = combineTimes(bag_data);
  end
% Did not find any messages. Return an empty table
else
  warning('Did not find any messages with the requested topic name in the bag file');
  bag_data = table();
end
end