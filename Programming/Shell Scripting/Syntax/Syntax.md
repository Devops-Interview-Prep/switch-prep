# Bash Scripting Syntax Reference

> Complete reference for bash scripting syntax — variables, arrays, conditionals, loops, functions, and more. Essential for DevOps automation, CI/CD scripts, and shell scripting interviews.

---

## Basics

```bash
# Check your current shell:
echo $0

# Shebang — tells OS which interpreter to use (always include):
#!/bin/bash

# Make script executable and run:
chmod +x script.sh
./script.sh          # run from current directory
/full/path/script.sh # run with absolute path
bash script.sh       # run without execute permission

# .sh extension not required but recommended for clarity
```

---

## Comments

```bash
# Single-line comment
echo "hello"  # inline comment

# Multi-line comment (heredoc trick):
<<comment
This is a
multi-line comment
comment

# Or use : with a string:
: '
This is also a comment block
Used less commonly
'
```

---

## Variables

```bash
# Define a variable (NO spaces around = sign):
VAR_NAME=value
NAME="John Doe"      # use quotes for values with spaces

# Use a variable:
echo "$VAR_NAME"     # always quote variables
echo "${VAR_NAME}"   # explicit braces (prevents ambiguity)

# Capture command output into variable:
current_date=$(date)
files=$(ls -la)
echo "Today is: $current_date"

# Read-only variable (cannot be changed later):
readonly MAX_RETRIES=3

# Unset a variable:
unset VAR_NAME

# Check if variable is set:
if [ -z "$VAR_NAME" ]; then
    echo "VAR_NAME is empty or not set"
fi

# Default value if not set:
echo "${VAR_NAME:-default_value}"

# Environment variables (visible to child processes):
export DATABASE_URL="postgres://localhost/mydb"
```

---

## Arrays

```bash
# Declare array:
myArray=(1 2 hello "Hey Man")

# Access elements:
echo "${myArray[0]}"       # first element: 1
echo "${myArray[2]}"       # third element: hello
echo "${myArray[@]}"       # all elements
echo "${myArray[*]}"       # all elements (slightly different with IFS)

# Array length:
echo "${#myArray[@]}"      # number of elements

# Slice (from index 1, next 3 elements):
echo "${myArray[@]:1:3}"

# Append to array:
myArray+=("new" "values")

# Iterate over array:
for item in "${myArray[@]}"; do
    echo "$item"
done

# Associative array (map/dictionary) — bash 4+:
declare -A myMap
myMap=( [name]=pawan [age]=27 )
echo "${myMap[name]}"      # pawan
echo "${!myMap[@]}"        # all keys: name age
```

---

## String Operations

```bash
var="my name is pawan"

# String length:
length=${#var}         # 18

# Uppercase / lowercase:
upper=${var^^}         # MY NAME IS PAWAN
lower=${var,,}         # my name is pawan

# Replace (first occurrence):
replace=${var/pawan/Bijesh}    # my name is Bijesh

# Replace all occurrences:
replace_all=${var//is/was}     # my name was pawan (replaces all "is")

# Substring (index 6, length 4):
slice=${var:6:4}       # "ame " (characters from index 6, 4 chars)

# Remove prefix:
path="/home/user/file.txt"
filename="${path##*/}"    # file.txt (longest match from left)
dir="${path%/*}"          # /home/user (removes shortest match from right)

# Extract extension:
ext="${filename##*.}"     # txt
```

---

## User Interaction

```bash
# Read input from terminal:
read var_name
echo "You entered: $var_name"

# Read with a prompt:
read -p "Enter your name: " name
echo "Hello, $name"

# Read silently (for passwords):
read -s -p "Enter password: " password
echo  # newline after silent input

# Read with timeout (5 seconds):
read -t 5 -p "Answer within 5s: " answer

# stty — control terminal echoing:
stty -echo    # disable echo (don't show typed characters)
read password
stty echo     # re-enable echo
```

---

## Arithmetic Operations

```bash
# Using let:
let a=5+3
let a++
let a=5*10

# Using (( )) — C-style:
((a++))
((a = 5 * 10))
((a > b)) && echo "a is greater"

# Use $(( )) in strings or for output:
echo "Result: $((5 * 10))"
echo "$((a + b))"

# bc for floating point:
echo "scale=2; 22/7" | bc    # 3.14
result=$(echo "1.5 * 2.0" | bc)

# Comparison operators (for arithmetic):
-gt    # greater than
-ge    # greater than or equal
-lt    # less than
-le    # less than or equal
-eq    # equal (numeric)
-ne    # not equal (numeric)
```

---

## Conditional Statements

```bash
# Basic if-else:
if [ condition ]; then
    echo "true"
elif [ other_condition ]; then
    echo "other"
else
    echo "false"
fi

# [ ] vs [[ ]] — enhanced test:
# [[ ]] supports regex, doesn't need to quote variables, supports && || inside
if [[ "$name" =~ ^[A-Z] ]]; then
    echo "starts with uppercase"
fi

# File test operators:
-f file     # regular file exists
-d file     # directory exists
-e file     # any file/dir/link exists
-s file     # file exists and is not empty
-r file     # readable
-w file     # writable
-x file     # executable
-L file     # symbolic link
-N file     # modified since last read

# String operators:
[ -z "$str" ]    # string is empty
[ -n "$str" ]    # string is not empty
[ "$a" == "$b" ] # strings are equal
[ "$a" != "$b" ] # strings are not equal

# Logical operators:
[ cond1 ] && [ cond2 ]    # AND (preferred)
[ cond1 ] || [ cond2 ]    # OR
[[ cond1 && cond2 ]]      # AND inside [[]]

# CASE statement:
read choice
case $choice in
    a) date ;;
    b) ls ;;
    start|run) echo "starting..." ;;
    *) echo "invalid input" ;;
esac
```

---

## Loops

```bash
# For loop — list of values:
for i in 1 2 3 4; do
    echo "$i"
done

# For loop — range:
for i in {1..10}; do echo "$i"; done

# For loop — C style:
for ((i=0; i<10; i++)); do
    echo "$i"
done

# For loop — over files:
for file in *.txt; do
    echo "Processing: $file"
done

# For loop — over command output:
for line in $(cat file.txt); do    # NOTE: splits by word, not line
    echo "$line"
done

# While loop:
count=0
while [ $count -lt 5 ]; do
    echo "$count"
    ((count++))
done

# Read file line by line (safe — preserves whitespace):
while IFS= read -r line; do
    echo "$line"
done < file.txt

# Read CSV file:
while IFS="," read -r f1 f2 f3; do
    echo "Col1: $f1, Col2: $f2"
done < data.csv

# Until loop (runs until condition is TRUE):
until [ $count -ge 5 ]; do
    echo "$count"
    ((count++))
done

# break and continue:
for i in {1..10}; do
    [ $i -eq 5 ] && break      # stop loop
    [ $i -eq 3 ] && continue   # skip this iteration
    echo "$i"
done
```

---

## Functions

```bash
# Define a function (two valid syntaxes):
function greet {
    echo "Hello, $1"
}

greet() {
    echo "Hello, $1"
}

# Call the function:
greet "World"   # Hello, World

# Function with local variables and return value:
add() {
    local n1=$1
    local n2=$2
    local sum=$((n1 + n2))
    echo "$sum"    # "return" via stdout
}

result=$(add 5 3)   # capture output
echo "$result"      # 8

# Bash functions can't return values the way other languages do
# Use echo to return, and $() to capture
# Use 'return N' for exit codes (0=success, 1-255=error)
```

---

## Arguments and Special Variables

```bash
# Script: ./script.sh arg1 arg2 arg3

$0      # script name
$1, $2  # positional arguments
$@      # all arguments as separate words: "$1" "$2" "$3"
$*      # all arguments as one word (joined by IFS)
$#      # number of arguments
$?      # exit code of last command (0=success)
$$      # current process PID
$!      # PID of last background process

# Shift — remove first argument:
echo "$1"    # arg1
shift
echo "$1"    # now arg2 (arg1 removed)

# Bash built-in variables:
RANDOM           # random integer 0-32767
UID              # current user ID
HOSTNAME         # machine hostname
SECONDS          # seconds since script started
LINENO           # current line number

# Random number in range [n1, n2]:
echo $((RANDOM % n2 + n1))
```

---

## Redirection and Debugging

```bash
# Redirect output:
command > file.txt      # stdout to file (overwrite)
command >> file.txt     # stdout to file (append)
command 2> error.txt    # stderr to file
command 2>&1            # redirect stderr to stdout
command &> /dev/null    # discard all output (stdout + stderr)
command 2>/dev/null     # discard only errors

# /dev/null — the black hole:
ls nonexistent &> /dev/null    # suppress all output

# Debugging:
set -x      # print each command before executing (trace mode)
set -e      # exit immediately if any command fails
set -u      # treat unset variables as error
set -o pipefail   # pipeline fails if any command in it fails

# Full safety header for production scripts:
#!/bin/bash
set -euo pipefail

# logger — write to syslog:
logger "MyScript: deployment started"
# logs to /var/log/messages (RHEL) or /var/log/syslog (Ubuntu)
```

---

## Background Execution and Scheduling

```bash
# Run in background:
./script.sh &              # background, output to terminal
nohup ./script.sh &        # background, immune to hangup (HUP), output to nohup.out
nohup ./script.sh > /dev/null 2>&1 &   # background, discard output

# AT — run once at a specific time:
at 3pm
    ./script.sh
# Ctrl+D to submit
atq                         # list scheduled jobs
atrm <job_id>              # remove a job

# Crontab — recurring schedule:
crontab -l    # list crons
crontab -e    # edit crons

# Format: minute hour day-of-month month day-of-week command
# *  *  *  *  *  command
# 0  2  *  *  *  /path/backup.sh     # every day at 2:00 AM
# */5 * * * *  /path/monitor.sh      # every 5 minutes
# 0  9  *  *  1  /path/report.sh     # every Monday at 9 AM

# Useful: https://crontab.guru for cron expression builder
```

---

## Compression and Archives

```bash
# tar — archive and compress:
tar -czf archive.tar.gz dir/          # compress directory with gzip
tar -cjf archive.tar.bz2 dir/         # compress with bzip2 (smaller, slower)
tar -xzf archive.tar.gz               # extract
tar -xzf archive.tar.gz -C /dest/     # extract to specific directory
tar -tzf archive.tar.gz               # list contents

# gzip — compress single files:
gzip file.txt                          # → file.txt.gz (removes original)
gzip -k file.txt                       # keep original
gunzip file.txt.gz                     # decompress

# zip — cross-platform archive:
zip -r archive.zip file1 dir/          # create
unzip archive.zip                      # extract
unzip -l archive.zip                   # list contents
zip -r --encrypt --password "$pass" folder.zip folder/   # password-protected
```

---

## Interview Q&A

**Q: What is the difference between `[ ]` and `[[ ]]` in bash conditionals?**
`[ ]` is the POSIX test command — portable across all POSIX shells but with limitations: variables must be quoted (unquoted expands unexpectedly), logical operators must be `-a`/`-o`, no regex support. `[[ ]]` is bash-specific built-in with improvements: no quoting required for most variables, supports `&&`/`||` inside, supports regex with `=~`, string comparison with `<`/`>`. For bash scripts, always prefer `[[ ]]`. For POSIX portability (scripts that run under `/bin/sh`), use `[ ]`.

**Q: Why must variable assignments have no spaces around `=`?**
In bash, `VAR=value` is a variable assignment. `VAR = value` is interpreted as running the command `VAR` with arguments `=` and `value` — which fails (command not found). This is because bash uses spaces as token delimiters. The `=` sign has no special meaning in command context; it's only special in `VAR=value` syntax where the entire token before `=` is the variable name and everything after is the value.

**Q: What does `set -euo pipefail` do and why use it?**
`set -e`: exit immediately if any command returns non-zero exit code (catches errors early). `set -u`: treat unset variables as an error — without this, `$UNSET_VAR` silently expands to "" which can cause subtle bugs. `set -o pipefail`: a pipeline like `cmd1 | cmd2` fails if any command in it fails — by default, the pipeline exit code is only the exit code of the last command. Together, they make scripts "strict mode" — fails fast and loudly on errors instead of silently continuing. Standard header for any production bash script.
