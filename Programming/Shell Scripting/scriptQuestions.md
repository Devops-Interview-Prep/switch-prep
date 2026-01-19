# Count lines, words, characters

```bash
read -s -p "Give File Name: " file 

wc -l < $file
wc -w < $file
wc -c < $file
```

# Reverse a file line by line

```bash
file="testFile.txt"

while IFS= read -r line 
do 
    echo "$line" | rev
done < $file
```

# Print the longest line and its length from a file.

```bash
file="testFile.txt"

length=0
# lineNumber=0
count=0

while IFS= read -r line 
do 
    count=$((count+1))
    x=${#line}
    if [ $x -gt $length ]
    then 
        length=$x
        longestLine=$line
    fi
done < $file

echo "$longestLine"

ORRR

awk '{print length($0),NR,$0}' $file | sort -nr | head -n 1 | awk '{for(i=3;i<=NF;i++) printf $i; print ""}'
```

# Word frequency counter

