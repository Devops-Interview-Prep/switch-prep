# 1. Write a Bash script that redirects the standard error (stderr) of a command to a file named "error.log".


#!/bin/bash

# Shebang line: Indicates the path to the shell interpreter (in this case, bash)

# Redirecting the standard error (stderr) of a command to a file named "error.log"
command_that_might_generate_errors 2> error.log

<<comment
'2>' symbol is used for stderr redirection, 
which redirects the standard error (stderr) output of the command to the file "error.log".
comment


# 2. Write a Bash script that redirects the output of the echo command to /dev/null to suppress any output.

echo "This output will be suppressed" > /dev/null

# 3. Write a Bash script that redirects the output of a command to another command as input, 
# such as ls | grep .txt to list only files with a ".txt" extension.

ls | grep '\.txt$'

<< comment
grep '\.txt$' filters the input from "ls", listing only lines that end with the ".txt" extension. \ is used to escape the dot . 
character in the regular expression pattern to match the literal dot character, and '$' represents the end of the line.
comment

# 4. Write a Bash script that uses input redirection to read a number from a file named "nums.txt" and 
# then performs some arithmetic operation on it.

read number < nums.txt
result=$((number * 2))

# Printing the result of the arithmetic operation
echo "The result of doubling the number from nums.txt is: $result"


# 5. Write a Bash script that uses a heredoc to input multi-line text and redirects it to a file named "document.txt".

cat <<EOF > nums.txt
This is line 1 of the document.
This is line 2 of the document.
This is line 3 of the document.
EOF






