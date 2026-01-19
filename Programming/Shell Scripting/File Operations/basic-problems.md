# Check if a file exists
  - `-f` for file
  - `-d` for directory 

```bash
if [-f "file_name"]
then 
    echo "file exists"
else
    echo "file does not exist"
fi
```

# Check if file exists and is not empty

```bash
if [-s "file_name"]
then 
    echo "file exists & not empty"
fi
```

# Count number of lines in a file

- `-l` for lines 
- `-w` for words 
- `-c` for characters 

```bash
wc -l < file_name
```

# Find a line containing a word in a file

- `-i` for case insensitve search
- `-n` print with line numbers 

```bash
 grep "word" file_name
```

# Search recursively in directory

```bash
grep -R "world" dir_name
```

# Replace text in a file (in-place)

- `sed -i 's/old/new/g' file_name`   for linux
- `sed -i '' 's/old/new/g' file_name` for mac
- `sed -i.bak 's/old/new/g' file_name` will create a bakup file for old file 

```bash
sed -i 's/old/new/g' file_name
```

# Delete empty lines from a file

```bash
sed '/^$/d' file.txt
```

# head and tail

```bash
head -n 10 file.txt     -> top 10 lines
tail -n 10 file.txt     -> bottom 10 lines 
```

# Monitor a growing file (logs)

```bash
tail -f /var/log/syslog
```

# Copy file preserving permissions

```bash
cp -p source.txt dest.txt
```

# Move file only if destination doesn’t exist

```bash
mv -n file.txt /backup/
```

# Delete files older than 7 days

```bash
find /folder -type f -mtime +7 -delete
```

# Find largest files
```bash
find /folder -type f exec du -h {} + | sort -hr | head -5
```

# Rename multiple files

```bash
for file in *.txt
do 
    mv "$f" "new_$f"
done
```

# Read file line by line 

```bash
while IFS= read -r line 
do 
    echo "$line"
done < concepts.md
```









