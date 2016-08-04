function [topic_names, topic_types] = bagInfo(bag_file, varargin)
% BAGINFO Reads the topic names and types in a ROS bag file
%	Usage: 
%   [topic_names, topic_types= BAGINFO(bag_file) returns the two 1 x n cell
%     arrays containing the topic names and types of messages in the bag
%     file.
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
%   Example: [names, types] = bagInfo('flight.bag');
%   Example: [names, types] = bagInfo('flight.bag', 'ros_root', '~/ros_catkin_ws/devel');

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
% Tell the parser how the possible inputs
addRequired(input_parser, 'bag_file', @ischar);
addParameter(input_parser, 'ros_root', default_ros_root, @ischar);

% Parse the inputs
parse(input_parser, bag_file, varargin{:});

% Check to make sure any directories the user passes in exist
assert(isempty(input_parser.Results.ros_root) || ...
  (exist(input_parser.Results.ros_root, 'dir') == 7), ...
  'Requested ROS root directory does not exist');

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

%% Bag interaction
% Call into the Python interface to get the names and types
bag_data = py.matlab_bag_helper.extract_topic_names_types(bag_file);
% Convert Python list types to Matlab cell arrays
topic_names = py2Matlab(bag_data{1});
topic_types = py2Matlab(bag_data{2});