function [] = setupEnv(ros_root)

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

if isempty(ros_root)
  if isempty(getenv('PYTHONPATH'))
    dir_names = dir('/opt/ros');
    dir_names = dir_names([dir_names.isdir]);
    ros_root = '';

    for dir_idx = 1:numel(dir_names)
      switch(dir_names(dir_idx).name)
        case 'indigo'
          ros_root = '/opt/ros/indigo';
        case 'jade'
          ros_root = '/opt/ros/jade';
        case 'kinetic'
          ros_root = '/opt/ros/kinetic';
        otherwise
      end
    end

    if isempty(ros_root)
      ros_root = fullfile('/opt/ros', dir_names(end).name);
      warning('Could not find a known ROS distribution, assuming your ROS distribution is rooted in %s', ros_root);
    end
    
    ros_root = fullfile(ros_root, 'lib/python2.7/dist-packages');
  end
end

if isempty(getenv('PYTHONPATH'))
  if exist(ros_root, 'dir') == 7
    P = py.sys.path;
    if ~strncmp(ros_root, cellfun(@char, cell(P), 'UniformOutput', false), length(ros_root))
      insert(P, int32(0), ros_root);
    end
  else
    error('Could not find location of ROS Python packages');
  end
end

end