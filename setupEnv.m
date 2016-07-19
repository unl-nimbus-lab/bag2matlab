function [] = setupEnv(ros_root)
% SETUPENV Set up Python environment for accessing ROS Python libraries
%   from Matlab. If the ROS_DISTRO environment variable exists, assume that
%   the environment is already correctly configured and do not modify the
%   Python path. Load the helper module once the environment is configured.
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

% Keep track of whether or not we have managed to load the helper module
persistent IMPORT_SUCCESS;

% Indicate that we have not loaded the helper module if this is the first time
% we have called this function
if(isempty(IMPORT_SUCCESS))
  IMPORT_SUCCESS = false;
end

% IF we have already import our Python module and the user is not
% overriding the root
if(IMPORT_SUCCESS && isempty(ros_root))
  return;
end

% Check to see if the user has specified where to search for the Python 
% packages. We will skip all our autodetection and use their path if this
% is the case
if(~isempty(ros_root))
  override_root = true;
else
  override_root = false;
end

% If the user has not specified the ROS Python modules are located, we will
% use the following code to try to find the packages if we have not managed
% to previously find them. If we have already loaded the module, do not 
% repeat this step
if(~override_root && ~IMPORT_SUCCESS)
  % If ROS_DISTRO is already an environment variable we assume that the
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
    % subdirectories, depending on the OS
    os = computer;
    if(strcmpi(os, 'MACI64'))
      ros_root = fullfile(ros_root, 'lib', 'python2.7', 'site-packages');
    else
      ros_root = fullfile(ros_root, 'lib', 'python2.7', 'dist-packages');
    end
  end
end

% Now modify our path to include to ROS modules if the environment variable was
% not preconfigured from the shell and we have not already loaded the module,
% or if the user has set a new ROS location
if((isempty(getenv('ROS_DISTRO')) && ~IMPORT_SUCCESS) || override_root)
  % Check if the target directory exists
  if(exist(ros_root, 'dir') == 7)
    modifyPath(ros_root);
  else
    error('Could not find location of ROS Python packages');
    IMPORT_SUCCESS = false;
  end
end

if(~IMPORT_SUCCESS || override_root)
  % Need to be in the directory where the helper Python script is located
  % to import it. Save our current directory, switch to that location, and
  % then restore the original directory at the end
  [function_path, ~, ~] = fileparts(which('setupEnv'));
  initial_path = pwd;
  cd(function_path);  
  try
    py.importlib.import_module('matlab_bag_helper');
  catch
    cd(initial_path);
    error('Could not import python helper function');
  end
  
  % Set flag indicating we have imported our helper function, and return to the
  % calling directory
  IMPORT_SUCCESS = true;
  cd(initial_path);
end

  function [] = modifyPath(module_location)
  % Helper function for adding the ROS Python modules to the path
    % Get the current modules Matlab knows about
    P = py.sys.path;
    % See if where we think the ROS modules are is already on the path
    if(~strncmp(...
        module_location, ...
        cellfun(@char, cell(P), 'UniformOutput', false), ...
        length(module_location)))
      % Modify the Python path with the location of the ROS modules
      insert(P, int32(0), module_location);
    end
  end
end