function [bag_data_table, bag_data_struct] = bagReader(bag_file, topic_name)
% bagReader Reads messages from a ROS bag file
%	Usage:	bagReader(bag_file, topic_name) returns a table and struct
%   of all the data published on the topic 'topic_name' in the bag 
%   'bag_file'.
%
%   bag_file is the path to the bag file to analyze
%   topic_name is a string containing the topic name to read
%
% Returns [bag_data_table, bag_data_struct]. These are representations of
%   the data as a table and struct array, respectively.

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

  % import our Python helper function
  try
    py.importlib.import_module('matlab_bag_helper');
  catch
    error('Could not import our matlab_bag_helper.py script');
  end
  
  % Read the data in the bag file
  bag_data_struct = py.matlab_bag_helper.read_bag(bag_file, topic_name);
  % Convert the Python data to an array of structurs
  bag_data_struct = py2Matlab(bag_data_struct);
  % Now make the Matlab structures a table
  bag_data_table = struct2table(bag_data_struct);
end