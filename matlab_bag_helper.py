#!/usr/bin/env python

#   Copyright (c) 2016 David Anthony
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

import rosbag
import unittest


class TestBagReader(unittest.TestCase):
    """ Put test cases here. These rely on paths to bag files on my local hard drive, so I have not committed them """
    pass


def read_bag(bag_file, topic_name):
    """ Reads all messages in a topic from a bag file.

        Opens up a bag file and reads all the messages in that bag file that match a topic name. Minimal error handling,
        so if the bag does not exist or the topic is not in the bag there will be strange behavior.

        Args:
            bag_file: A path to the bag file
            topic_name: A string containing the topic name to read out

        Returns:
            A list of dictionaries. Each dictionary is a single message in the bag. The list is each message as it was
            encountered in the bag file.
    """

    # Open the bag file
    file_data = rosbag.Bag(bag_file)

    # Initialize the output
    extracted_data = []

    # Iterative over every message in the bag that matches our topic name
    for _, msg, _ in file_data.read_messages(topics=topic_name):
        # Add the extracted data to our output list
        extracted_data.append(extract_topic_data(msg))

    # Clean up after ourselves
    file_data.close()

    # Return the extracted messages
    return extracted_data


def extract_topic_data(msg):
    """ Reads all data in a message

        This is a recursive function. Given a message, extract all of the data in the message to a dictionary. The keys
        of the dictionary are the field names within the message, and the values are the values of the fields in the
        message. Recursively call this function on a message to build up a dictionary of dictionaries representing the
        ROS message.

        Args:
            msg: A ROS message

        Returns:
            A dictionary containing all information found in the message.
    """
    # Initialize the information found for this message
    data = {}

    # If the message has slots, we have a non-primitive type, and need to extract all of the information from this
    # message by recursively calling this function on the data in that slot. For example, we may have a message with a
    # geometry_msgs/Vector3 as a field. Call this function on that field to get the x, y, and z components
    if hasattr(msg, '__slots__'):
        # Extract all information on a non-primitive type
        for slot in msg.__slots__:
            data[slot] = extract_topic_data(getattr(msg, slot))
    else:
        # We encountered a primitive type, like a double. Just return it so it gets put into the output dictionary
        return msg

    # Return the dictionary representing all of the fields and their information in this message
    return data

def display_bag_topics( bag_file ):
	""" Query the topic names in a bag file.
	
	 AJ: this gets called to display topics in a bag when no topics are specified from the original Matlab call.
	 
	 	-- Uses YAML to extract all information from a bag file, similar to the cmd line "rosbag info",
	 		then loops through the returned dictionary to get topic names.
	 NOTE TO HUMANS FROM THE FUTURE:
	 The returned dictionary has more information such as message name, type, frequency and number.
	 I have neither the time, nor the need for any of those .. yet ..
	 
	 Args:
	 	bag_file: name of the bag file.
	 Returns:
	 	a list of Python strings.
	 
	 """
	bag = rosbag.Bag( bag_file );
	
	# Get a convoluted dictionary of lists of dictionaries. Awesome.
	topic_dict = yaml.load( bag._get_yaml_info() );
	
	# Create a list of strings
	topic_list = [];
	
	# Fill in the topic names from the extracted dictionary.
	# I'm pretty sure there's an easier way of doing this without a loop.
	# 	.. I shall await the ancient wisdom of some Python wizard ..
	for topic_num in range( len(topic_dict['topics']) ):
		topic_list.append( topic_dict['topics'][topic_num]['topic'] );
	return topic_list
		

if __name__ == "__main__":
    unittest.main()
