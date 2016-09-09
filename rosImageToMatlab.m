function [matlab_image] = rosImageToMatlab(ros_image, encoding, height, width)
% rosImageToMatlab Convert ROS image representation to Matlab format
%	Usage:	rosImageToMatlab(ros_image, encoding, height, width) Converts the
%           data in ros_image to a format usable in Matlab. ros_image is a
%           1D vector, such as that defined in sensor_msgs/Image. encoding
%           is the ROS encoding string that is in sensor_msgs/Image. height
%           and width are the height and width of the image as defined in a
%           ROS image message.
%
% Please note that not all image encodings are currently supported. More
% will be added as needed.

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

switch encoding
  case 'mono8'
    convertMono8();
  case 'bgr8'
    convertBGR8();
  otherwise
    error('Unsupported encoding');
end

  function [] = convertMono8()
    matlab_image = reshape(uint8(ros_image), width, height)';
  end

  function [] = convertBGR8()
    % Converts ROS BGR8 image representation to a Matlab representation
    
    % Preallocate output
    matlab_image = zeros(height, width, 3);
    read_idx = 1;
    
    % BGR8 ends up being a height x width x 3 array. The ROS image is
    % repeated tuples of blue, green, and red. Read 3 bytes at a time and
    % place them into the Matlab format.
    for row_idx = 1:height
      for col_idx = 1:width
        matlab_image(row_idx, col_idx, 1) = ros_image(read_idx + 2); 
        matlab_image(row_idx, col_idx, 2) = ros_image(read_idx + 1); 
        matlab_image(row_idx, col_idx, 3) = ros_image(read_idx);
        read_idx = read_idx + 3;
      end 
    end 
      
    matlab_image = uint8(matlab_image);
  end
end
