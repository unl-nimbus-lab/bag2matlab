# bag2matlab
This repo has Matlab and Python code for reading data from a ROS bag file directly into a Matlab workspace. See the documentation for bagReader.m for information on how to use the code. This requires Matlab and ROS to run. Tested with ROS Kinetic Kame and Matlab R2015b.

This tool is invoked from with Matlab. Simply call bagReader.m with the bag name and the topic to read to get all of the data from that topic as a table. For example, `bagReader('flight.bag', '/uav/pose')` will read all of the data published on the '/uav/pose' topic that is stored within 'flight.bag'. Calling `bagReader` with only the first argument (bag name) returns a list of available topics in the bag as a table.
