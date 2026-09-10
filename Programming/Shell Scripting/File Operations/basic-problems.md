# Shell Scripting — File Operations

> Common file operation patterns in bash: checking existence, reading content, searching, and modifying files. These are fundamental for DevOps automation scripts.

---

## File and Directory Existence Checks

```bash
# Check if file exists:
if [ -f "file.txt" ]; then
    echo "file exists"
else
    echo "file does not exist"
fi

# Check if directory exists:
if [ -d "/var/log/app" ]; then
    echo "directory exists"
fi

# Combined: file exists AND is not empty:
if [ -s "file.txt" ]; then
    echo "file exists and is not empty"
fi

# File test operators:
# -f    regular file exists
# -d    directory exists
# -e    any file/dir/link exists
# -s    file exists and is not empty (size > 0)
# -r    file is readable
# -w    file is writable
# -x    file is executable
# -L    is a symbolic link
# -z    string is empty (zero length)
# -n    string is non-empty

# Check multiple conditions:
if [ -f "config.sh" ] && [ -r "config.sh" ]; then
    source "config.sh"
fi
```

---

## Reading and Searching Files

```bash
# Count lines, words, characters:
wc -l file.txt           # line count
wc -w file.txt           # word count
wc -c file.txt           # byte count
wc file.txt              # all three at once

# Head and tail:
head -n 10 file.txt      # first 10 lines
tail -n 10 file.txt      # last 10 lines
tail -f /var/log/app.log # follow (live updates as file grows)
tail -n 0 -f app.log     # follow from end (skip existing lines)

# Search for pattern:
grep "error" file.txt                  # lines containing "error"
grep -i "error" file.txt               # case-insensitive
grep -n "error" file.txt               # with line numbers
grep -c "error" file.txt               # count matching lines only
grep -v "debug" file.txt               # lines NOT containing "debug"
grep -r "pattern" /var/log/            # recursive search in directory

# Read file line by line (safe — handles spaces and special chars):
while IFS= read -r line; do
    echo "$line"
done < file.txt

# Read file into array:
mapfile -t lines < file.txt            # bash 4+
echo "${lines[0]}"                     # first line
echo "${#lines[@]}"                    # number of lines
```

---

## Modifying Files

```bash
# Replace text in a file (in-place):
sed -i 's/old/new/g' file.txt              # Linux (GNU sed)
sed -i '' 's/old/new/g' file.txt           # macOS (BSD sed — requires empty string)
sed -i.bak 's/old/new/g' file.txt         # creates file.txt.bak backup first

# Delete empty lines:
sed -i '/^$/d' file.txt

# Delete comment lines:
sed -i '/^#/d' file.txt

# Delete both empty lines and comments:
sed -i '/^$/d; /^#/d' file.txt

# Append a line to a file:
echo "new line" >> file.txt

# Prepend a line to a file:
sed -i '1i\new first line' file.txt

# Add text after a matching line:
sed -i '/match_pattern/a\new line after match' file.txt
```

---

## Copying, Moving, and Deleting

```bash
# Copy preserving timestamps and permissions:
cp -p source.txt dest.txt
cp -rp source_dir/ dest_dir/        # recursive + preserve

# Move only if destination doesn't exist (no overwrite):
mv -n file.txt /backup/

# Move with verbose output:
mv -v file.txt /backup/

# Delete files older than 7 days:
find /var/log -type f -mtime +7 -delete

# Find and delete specific pattern:
find . -name "*.log" -type f -delete

# Find largest files in a directory:
find /var -type f -exec du -h {} + | sort -hr | head -5

# Safer: list what would be deleted before actually deleting:
find /var/log -type f -mtime +7            # list candidates
find /var/log -type f -mtime +7 -delete   # then delete
```

---

## Renaming Multiple Files

```bash
# Rename all .txt files with "new_" prefix:
for file in *.txt; do
    mv "$file" "new_$file"
done

# Rename with date stamp:
for file in *.log; do
    mv "$file" "${file%.log}_$(date +%Y%m%d).log"
done

# Change extension from .txt to .md:
for file in *.txt; do
    mv "$file" "${file%.txt}.md"
done
```

---

## Interview Q&A

**Q: What is the difference between `-f`, `-e`, and `-s` in file tests?**
`-e` is the broadest: it's true if the path exists as any type (regular file, directory, symlink, device). `-f` is true only for regular files (not directories or symlinks to directories). `-s` is `-f` plus "not empty" — file exists AND has at least 1 byte. For checking if a config file is ready to source: use `-s` (exists and has content), not just `-e`. For checking a binary to execute: use `-x` (executable bit is set).

**Q: Why use `IFS= read -r line` instead of just `read line`?**
Without `IFS=`: `read` strips leading/trailing whitespace from each line — lines indented with spaces lose their indentation. Without `-r`: backslashes in the file are treated as escape characters, so `\n` in a line becomes a literal newline and `\\` becomes `\`. The combination `IFS= read -r line` reads exactly what's in the file, byte for byte on each line. This is the canonical "safe file reading" pattern for any production script.

**Q: How do you handle filenames with spaces when processing files in a loop?**
Always double-quote the variable: `"$file"`, not `$file`. Without quotes, `file="my document.txt"` and `mv $file /backup/` expands to `mv my document.txt /backup/` — three arguments, not two. With quotes: `mv "$file" /backup/` correctly passes the filename with space as one argument. For `find`, use `-print0` with `while IFS= read -r -d '' file; do ... done < <(find . -print0)` to handle both spaces and newlines in filenames.
