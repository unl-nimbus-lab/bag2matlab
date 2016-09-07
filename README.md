# bag2matlab
This repo has Matlab and Python code for reading data from a ROS bag file directly into a Matlab workspace. See the documentation for bagReader.m and bagInfo.m for information on how to use the code. This requires Matlab and ROS to run. Tested with ROS Kinetic Kame, Matlab R2015b, and R2016b.

The bagReader() Matlab script reads all data from a bag for a given topic. Simply call bagReader.m with the bag name and the topic to read to get all of the data from that topic as a table. For example, bagReader('flight.bag', '/uav/pose') will read all of the data published on the '/uav/pose' topic that is stored within 'flight.bag'.

bagInfo() returns the names and types of all the topics in a bag. For example: bagInfo('flight.bag') will return two cell arrays, one with the topic names, and the other with the corresponding types.

For convenience, there is also a Matlab function for converting ROS images from sensor_msgs/Image messages to a representation Matlab can understand. This functionality is in rosImageToMatlab.m. Currently, only mono8 and bgr8 conversions are supported.
