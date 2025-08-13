#!/opt/homebrew/bin/bash

#awk '{print $NF}' file.txt    # awk traverse whole file line by line $1 is the first field of every line 

#awk '{print NR,$1}' file.txt     # this will print the first field of every line , with line number

# awk 'NR==1 {print $1}' file.txt    # this will print the first field of first line 

# awk 'NR==1 {print NR,$1}' file.txt   # this will print the first field of first line with line number

# awk '{print NR,"anything",$1}' file.txt   # his will print the first field of every line , with line number and anything between them

# awk -F, '{print $4}' file.csv  # This will print the 4th column of the comma seprated csv file

# awk '{print $0}' file.txt    # $0 means whole line 


# awk 'NR != 1 {if($3>2000000) print $0}' file.txt

# awk 'NR != 1 {if($3>1600000) {$4="Hariyana"} print $0}' file.txt

# awk '/Rajasthan/ {print $0}' file.txt # will return the lines with word <word>


# awk 'NR==2,NR==4 {print $0}' file.txt # will display 2,3,4 lines

# awk 'NF==0 {print NR}' file.txt  # will display the empty line numbers 

# awk 'NF!=0 {print $0}' file.txt > file.txt  # will display non empty lines 

# awk 'END {print NR}' file.txt # will give you total number of lines 

# awk 'NR==3  {for(i=2;i<=NF;i++) {if($i=="pawan"){$i="xyz"}} print}' file.txt

# awk '{ print tolower($0)}' file.txt

