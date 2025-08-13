# Basics

1. Check your shell 

`echo $0`

2. Shebang - to tell which shell to use , not required if default shell is bash but recommeded

`#!/bin/bash`

3. `.sh` is not required but recommeneded 

4. To run a script give rwx permission first and then use 

`./script.sh`  or `/path/script.sh` or `bash script.sh`


# Comments 

1. Use #

`#This is a comment`

2. Use `<<comment .... comment`

```
<<comment
this is a commented 
paragraph
comment
```

# Variables

```
VAR_NAME=value

use it anywhere in the script as $VAR_NAME

```

- we should not use spaces at any sides of the = operator 

**Store output of a command into variable**

`variable=$(command)`

use it as $variable 

- Define a variable in a way so that it cant be changed during the whole script 

`readonly var_name=values`


# Arrays

myArray=(1 2 hello "Hey Man")

`echo "${myArray[0]}"`

- Use `${myArray[*]}` to get all the values
- Use `${#myArray[*]}` to get length of the array
- Use `${myArray[*]:1}` to get value at index 1
- Use `${myArray[*]:1:3}` to get next 3 values including index 1

**Update the Array**

- Append values using `myArray+=( new values )`


**Array as Map**
```
declare -A myArray

myArray=( [name]=pawan [age]=27 )

echo "${myArray[name]}"

```

# String Operations

```
var="my name is pawan"

length=${#var}

upper=${var^^}

lower=${var,,}

replace=${var/pawan/Bijesh}

slice=${var:6:11}  # will give index 6 to 11 not similar to array

```


# User Interaction

`read var`

- terminal will ask for the input

`read -p "message" var`
`read -s var`
This will ask you input that wont be visible in terminal

- To read with messqage 

- `stty -echo`
  - This command disables echoing of characters, so the password input is not displayed on the screen.
- `stty echo`
  - This command re-enables echoing of characters after the password has been entered.


# Airthmetic Operations

```
#Using let

let a++

let a=5*10

#Without let

((a++))

((a=5*10))

use $(()) when using in string or printing it 

```


# Conditional Statements 

**IF-ELSE**

```
if [ cod1 ] && [ cond2 ]
then
...
else
.....
fi

# use if[[]] for inhanced version

```
- Use `if [[ "$input" =~ ^[0-9]+$ ]]` for comparing regex

- for greater than use `-gt`
- for greater than equal to use `-ge`
- for less than use `-lt`
- for less than equal to use `-le`
- for numerice equal use `-eq`
- for string equal use `==`

```
# These check if files/directories exist or have certain properties:

Flag	                Meaning
-e file	                File exists (any type)
-f file	                File exists and is a regular file
-d file	                File exists and is a directory
-s file	                File exists and is not empty
-L file	                File is a symbolic link
-r file	                File is readable
-w file	                File is writable
-x file	                File is executable
-b file	                File is a block special file (device)
-c file	                File is a character special file
-h file	                File is a symbolic link (same as -L)
-p file	                File is a named pipe (FIFO)
-S file	                File is a socket
-N file	                File was modified since last read
file1 -nt file2	        File1 is newer than file2
file1 -ot file2	        File1 is older than file2
file1 -ef file2	        File1 and file2 are the same file (hard links, etc.)


# Used to compare strings:

Expression	                Meaning
= or ==	                    Strings are equal (== only in [[ ]])
!=	                        Strings are not equal
<	                        String1 is less than string2 (lexicographically, [[ ]] only)
>	                        String1 is greater than string2 (lexicographically, [[ ]] only)
-z string	                String is empty
-n string	                String is not empty

# Used to combine conditions:

Operator	                Meaning
-a	                        Logical AND (used in [ ])
-o	                        Logical OR (used in [ ])
!	                        NOT
&&	                        AND (preferred in [[ ]])

```


**CASE**

```
read choice

case $choice in 
    a)date;;
    b)ls;;
    *)echo "not a valid input"
esac


#For multiline Statements

case $choice in 
    a)
            date;;
            echo "something"
            ;;
    b)ls;;
    *)echo "not a valid input"
esac
```


# for loop 

```
for i in 1 2 3 4 
do 
....
done

# break and continue can be used as it is 
```

```
for i in str1 str2 str3 

for i in {1..10}
```
```
# Iterate values from file over every value not line

for item in $(cat file.txt)
do 
    echo "$item"
done
```

```
for (( i=0;i<length;i++ ))  // ((;;)) for infinite loop
do
    ..
done
```


# While Loop

```
while [ condition ]   # keep condition as true to make an infinite loop
do
    ...
done
```
```
# Read content from a file 

while read var
do
    echo "$var"
done < file.txt
```

```
#To read content from a csv file 

while IFS="," read f1 f2   #IFS - internal feild seprator
do 
    echo -e "$f1\n$f2"
done < file.csv
```

# Until Loop

```
until the condition is false 
until [ condition ] 
do
    ...
done
```

# Function

```
function myfun {
    ...
}

or 

myfun() {
    ...
}


myfun # call the function
```

```
# Functions with Arguments 

fun() {
    local n1=$1
    local n2=$2

    let sum=$n1+$n2

    echo "$sum"
}

fun 12 15  # calling the function with arguments
```


# Arguments in a Script

- To get no of arguments : `$#`
- To display all the arguments : `$@`
- To use or display an argument : `$1, $2`


# Shifting of Arguments

```
$1 
shift   # this will club all the args in one arg after 1st arg
$@
```


# Useful Commands 

- `sleep` create delay between two executions 
- `exit 1` to stop script at a point 
- `$?` exit status of last command
- `basename` to get file name without the dir info 
- `dirname` to get the dir name without the file info
- `realpath` to get functional path of the file
- `if [ -d/f foldername/filename ]` -> d for folder, f for file
- `if [ ! -d/f foldername ]`

# Bash Variables

- `RANDOM` - a random integer between 0 to 32767 is generated 
  - `RANDOM%n2 + n1` - to get random number between n1 to n2
- `UID`


# Redirect Output

- If we dont want to print the output on terminal or write in a file then we can redirect the output to `/dev/null`
- This means you are garbaging the output it wont get stored anywhere 
- ex. `ls dir &> /dev/null`
- Redirect error
  - `2>`
- Redirect both error and output
  - `2>&1`

# Logs 

- use `logger` to write logs 
- these logs will be stored in `/var/logs/messages`


# Debugging 

- use `set -x` in the start of the script 
- Use `set -e` if we want our script to exit after a fail command

# Run the Script in background

- use `nohup script.sh &` 
- We can run in bg just by using `&` in the end but that wont save the output anywhere 
- using nohup will save the output in `nohup.out`


# Scheduling of the Script 

1. Using `AT`
    ```
    at <Time>
        ./script.sh
    # ctrl+D use to schedule

    # atq to see scheduled jobs
    # atrm <id>  to remove the scheduled job
    ```

2. Using `crontab`
    ```
    crontab -l   # To list all the crons
    crontab -e   # To create a cron tab

    ***** command # * for cron tab 

    5th * - day of the week ( starts 0 as sunday)
    4th * - month of the year ( 1 to 12)
    3rd * - Day of the month (1 to 31)
    2nd * - Hour of the day (0 - 23 )
    1st * - Minute of the hour (0 - 59 ) 

    # Use crontab.guru

    ```


# free command 

- `free -h` shows memory used and free
- `free -mt` shows total memory used and free

# file

- `${file##*.}` extracts file extenstion
- The `chmod go= file` means:
  - g= : Removes all permissions for the group.
  - o= : Removes all permissions for others.
- u stands for owner 
- g stands for group 
- o stands for other 
- +/-r for read permission
- +/-w & +/-x for write and execute permission

# Compress and Archive 

1. `tar`  - Archiving and (optionally) compressing
    - archive only  `tar -cf archive.tar file1 file2 folder/`
    - Archive + compress using gzip - `tar -czf archive.tar.gz file1 file2 folder/`
    - Extract any tar archive 
      - `tar -xf archive.tar`
      - `tar -xzf archive.tar.gz`

2. `gzip` – Compress single files
    - `gzip file.txt`  # creates file.txt.gz
    - `gunzip file.txt.gz`  # restores file.txt

3. `zip` – Archive and compress in one step
    -  `zip -r archive.zip file1 file2 folder/`    Compress files/folders into .zip
    -  `unzip archive.zip`

- Compress a Directory into a Zip Archive with Password Protection:

`zip -r --encrypt --password "$password" folder.zip folder`



 










