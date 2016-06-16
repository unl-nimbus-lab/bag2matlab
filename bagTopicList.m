function [topic_list] = bagTopicList( bag_file )
% Function to query only the list of topics from a bag file
% INPUT:
%       bag_file: name of the bag file
% RETURNS:
%       topic_list: a table of list of topics-names.
%
% Note: the returned variable is a table to conform with the return-type of
% the parent bagReader function that calls this one. Also, this allows for
% addition of more variables (like topic attributes) to the table, if some
% substantially crazy individual feels the need to.

    % Call the Python function
	topic_list = py.matlab_bag_helper.display_bag_topics( bag_file );
    % Split the returned py.list to cell-array of py.list,
    % convert those to cell-array of chars, and the final cells to a table.
    topic_list = cell2table( cellfun( @char, cell(topic_list), 'UniformOutput', false )', 'VariableNames', {'Topics'} );
end
