#!/opt/homebrew/bin/bash

# create files using args from a file
# cat "files.txt" | xargs touch

# create dirs using args from a file

#cat "dirs.txt" | xargs mkdir
#  How do you find and delete all .log files older than 7 days in current directory?


# find . -type f -name "*.log" -exec rm {} +


# Write a script to count the number of empty files in a directory and its subdirectories.

find . -type f -empty | wc -l

# match regex 

find . -type f ! -regex ".*\.txt$" 