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

from __future__ import division
import os
import rosbag
import unittest


class TestBagReader(unittest.TestCase):
    """ Put test cases here. These rely on paths to bag files on my local hard drive, so I have not committed them """
    pass


def read_bag(bag_file, topic_name, min_idx, max_idx):
    """ Reads all messages in a topic from a bag file.

        Opens up a bag file and reads all the messages in that bag file that match a topic name. Minimal error handling,
        so if the bag does not exist or the topic is not in the bag there will be strange behavior.

        Args:
            bag_file: A path to the bag file
            topic_name: A string containing the topic name to read out
            min_idx: An integer containing the first message index to return
            max_idx: An integer containing the last message index to return

        Returns:
            A list of dictionaries. Each dictionary is a single message in the bag. The list is each message as it was
            encountered in the bag file.
    """

    # Check that the index bounds are reasonable
    assert min_idx >= 0
    assert max_idx >= min_idx

    # Open the bag file
    file_data = rosbag.Bag(os.path.abspath(os.path.expanduser(bag_file)))

    # Initialize the output
    extracted_data = []

    # Initialize the counter for keeping track of whether or not we are within the minimum/maximum index
    msg_idx = 0

    # Iterate over every message in the bag that matches our topic name
    for _, msg, t in file_data.read_messages(topics=topic_name):
        # Check if we are past the start of the location in the bag file to read from
        if msg_idx >= min_idx:
            # Add the extracted data to our output list
            data = extract_topic_data(msg, t)
            # Convert the time the message the message was recorded in the bag file to a single scalar value and add it
            # to the new data
            data['rosbag_recv_time'] = t.secs + (t.nsecs / 1e9)
            # Add the new data to the set we return to the caller
            extracted_data.append(data)
        # Increment the index and bail from the loop early if we have advanced past the last message of interest. This
        # early exit can yield significant performance gains
        msg_idx += 1
        if msg_idx > max_idx:
            break

    # Clean up after ourselves
    file_data.close()

    # Return the extracted messages
    return extracted_data


def extract_topic_names_types(bag_file):
    """ Gets the topic names and types of messages in a bag file.

        Opens up the bag file and reads the topic names and types of the messages in that bag file. Uses code from the
        ROS bag cookbook.

        Args:
            bag_file: path to the bag file

        Returns:
            A tuple of lists. The first list is the topic names, and the second list is the topic types.
    """
    bag = rosbag.Bag(os.path.abspath(os.path.expanduser(bag_file)))
    topics = bag.get_type_and_topic_info()[1].keys()
    types = []
    for i in range(0, len(bag.get_type_and_topic_info()[1].values())):
        types.append(bag.get_type_and_topic_info()[1].values()[i][0])
    return topics, types


def extract_topic_data(msg, t):
    """ Reads all data in a message

        This is a recursive function. Given a message, extract all of the data in the message to a dictionary. The keys
        of the dictionary are the field names within the message, and the values are the values of the fields in the
        message. Recursively call this function on a message to build up a dictionary of dictionaries representing the
        ROS message.

        Args:
            msg: A ROS message
            t: Time the message was recorded in the bag file

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
            data[slot] = extract_topic_data(getattr(msg, slot), t)
    else:
        # We encountered a primitive type, like a double. Just return it so it gets put into the output dictionary
        return msg

    # Return the dictionary representing all of the fields and their information in this message
    return data


if __name__ == "__main__":
    unittest.main()
