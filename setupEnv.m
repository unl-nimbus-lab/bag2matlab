function [] = setupEnv(ros_root)
% SETUPENV Set up Python environment for accessing ROS Python libraries
%   from Matlab. If the ROS_DISTRO environment variable exists, assume that
%   the environment is already correctly configured and do not modify the
%   Python path
%
% Usage:
%   SETUPENV('') Search /opt/ros for ROS installations and add the Python
%     modules in those directories.
%
%   SETUPENV(path) Search the specified path for Python modules

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

% Check to see if the user has specified where to search for the Python 
% packages. We will skip all our autodetection and use their path if this
% is the case
if(~isempty(ros_root))
  override_root = true;
else
  override_root = false;
end

% If the user has not specified the ROS Python modules are located, we will
% use the following code to try to find the packages
if(~override_root)
  % If ROS_DISTRO is already and environment variable we assume that the
  % rest of the system is already configured and do not do anything
  if(isempty(getenv('ROS_DISTRO')))
    % Look in the default ROS installation location for ROS distributions
    % and use the latest as the ROS source directory
    dir_names = dir('/opt/ros');
    dir_names = dir_names([dir_names.isdir]);
    ros_root = '';

    % Iterate through the found directories and add the latest ROS
    % distribution as the ROS root location. By placing the switch clauses
    % in alphabetical order we should grab the latest distribution.
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

    % We did not find a known ROS distribution. Just try using the last
    % directory in /opt/ros and warn the user things may be bad.
    if(isempty(ros_root))
      ros_root = fullfile('/opt/ros', dir_names(end).name);
      warning('Could not find a known ROS distribution, assuming your ROS distribution is rooted in %s', ros_root);
    end
    
    % Assume that all of ROS's Python modules are nested in the following
    % subdirectory
    ros_root = fullfile(ros_root, 'lib/python2.7/dist-packages');
  end
end

% Now modify our path to include to ROS modules
if(isempty(getenv('ROS_DISTRO')) || override_root)
  if(exist(ros_root, 'dir') == 7)
    P = py.sys.path;
    % This stops us from repeatedly adding the the directory to the Python
    % path
    if(~strncmp(ros_root, cellfun(@char, cell(P), 'UniformOutput', false), length(ros_root)))
      % Modify the Python path with the location of the Python modules
      insert(P, int32(0), ros_root);
    end
  else
    error('Could not find location of ROS Python packages');
  end
end

end