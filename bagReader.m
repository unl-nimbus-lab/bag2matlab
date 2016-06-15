function [bag_data] = bagReader(bag_file, topic_name, varargin)
% BAGREADER Reads messages from a ROS bag file
%	Usage: 
%   bag_data = BAGREADER(bag_file, topic_name) returns a table of all 
%     the data published on the topic 'topic_name' in the bag 'bag_file'.
%
%     bag_file is the path to the bag file to analyze
%     topic_name is a string containing the topic name to read
%
%   BAGREADER(bag_file, topic_name, 'ros_root', path) Specifies the
%     location of the ROS distribution so the function can find the Python
%     packages it depends on. This is useful if ROS is built from source
%     and not installed in a standard location. If this pair is not
%     specified, the function will check if the PYTHONPATH environment
%     variable is set. If it is not, then it will scan /opt/ros and look
%     for distribution folders there.
%
%   Example: pose = bagReader('flight.bag', '/uav/pose');
%   Example: pose = bagReader('flight.bag', '/uav/pose', 'ros_root', '~/ros_catkin_ws/devel');

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
default_ros_root = '';
addRequired(input_parser, 'bag_file', @ischar);
addRequired(input_parser, 'topic_name', @ischar);
addParameter(input_parser, 'ros_root', default_ros_root, @ischar);
parse(input_parser, bag_file, topic_name, varargin{:});

assert(isempty(input_parser.Results.ros_root) || ...
  (exist(input_parser.Results.ros_root, 'dir') == 7), ...
  'Requested ROS root directory does not exist');
assert(exist(input_parser.Results.bag_file, 'file') == 2, ...
  'Bag file does not exist');

%% Python setup
% Add the location of the Python packages for ROS to our path because our
% script relies on their functionality
setupEnv(input_parser.Results.ros_root);

% Now import our Python helper function
try
  % Need to be in the directory where the helper Python script is located
  % to source it. Save our current directory, switch to that location, and
  % then restore the original directory
  [function_path, ~, ~] = fileparts(which('bagReader'));
  current_path = pwd;
  cd(function_path);
  py.importlib.import_module('matlab_bag_helper');
  cd(current_path);
catch
  error('Could not import our matlab_bag_helper.py script');
end

%% Bag reading
% Read the data in the bag file
bag_data = py.matlab_bag_helper.read_bag(bag_file, topic_name);
% Convert the Python data to an array of structurs
bag_data = py2Matlab(bag_data);
% Now make the Matlab structures a table
bag_data = struct2table(bag_data);
% Flatten the table
bag_data = flattenTable(bag_data);
end