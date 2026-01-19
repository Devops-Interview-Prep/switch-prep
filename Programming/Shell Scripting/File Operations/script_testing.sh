#!/bin/bash

# for line in "$(cat concepts.md)"
# do 
#     echo "$line"
# done

while IFS= read -r line
do 
    echo "$line"
done < concepts.md