#!/bin/bash

file="testFile.txt"

while IFS= read -r line 
do
    for word in $line 
    do 
        map=$(echo"$word $(grep "$word" < $file | wc -w)" )
    done
done < $file 








