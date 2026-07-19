# File Descriptors

- It is an integer that represents an open file
- Types:
  - Standard Input(stdin)   -> File Descriptor 0
  - Standard Output(stdout) -> File Descriptor 1
  - Standard ERR(stderr)    -> File Descriptor 2
- These discriptors help the system understand where to send or recieve the data 


# Redirection 

- `>`   output redirection
- `>>`  append outputs in the file
- `2>`  Error Redirection
- `2>>` Append error outputs
- `&>`  Both output and error redirection 
- `&>>` Append output or error both 

- `<` file input redirection
- `<<EOF` multiline input redirection

---

## Practical Redirection Examples

```bash
# Redirect stdout to file (overwrites)
ls -la > files.txt

# Append stdout to file
echo "new line" >> log.txt

# Redirect only errors (discard them)
command 2>/dev/null

# Redirect both stdout and stderr to same file
command > all.log 2>&1
# (same as)
command &> all.log

# Append both stdout and stderr
command &>> all.log

# Use file as stdin
mysql -u root -p mydb < schema.sql

# Heredoc — multiline input redirection
cat <<EOF > config.yaml
server: localhost
port: 8080
debug: true
EOF

# Heredoc with command substitution
ssh user@server <<EOF
sudo systemctl restart nginx
sudo journalctl -n 50 nginx
EOF
```

## Pipelines

```bash
# Pipe stdout of one command to stdin of next
cat /var/log/syslog | grep "ERROR" | tail -20

# Pipe stderr through pipeline (merge stderr into stdout first)
command 2>&1 | grep "error"

# tee — write to file AND pass through to stdout
command | tee output.txt | grep "important"

# Save stdout while still seeing it in terminal
long-running-script | tee script.log
```

## /dev/null — The Trash

```bash
# Discard output (silence a command)
noisy-command > /dev/null 2>&1

# Discard only errors (keep stdout)
command 2>/dev/null

# Read nothing (empty input)
cat /dev/null > file.txt   # empty the file
```

## Process Substitution

```bash
# diff two command outputs directly (no temp files)
diff <(ls dir1) <(ls dir2)

# Feed command output as a file argument
while read line; do echo "→ $line"; done < <(cat hosts.txt)
```

## Common Interview Questions

**Q: Difference between `2>&1` and `&>`?**
`2>&1` redirects file descriptor 2 (stderr) to wherever fd 1 (stdout) currently points. Order matters: `> file 2>&1` works; `2>&1 > file` doesn't (redirects stderr to old stdout, then stdout to file). `&>` is bash shorthand for both — equivalent to `> file 2>&1` and order doesn't matter.

**Q: What does `/dev/null` do?**
`/dev/null` is a special file that discards everything written to it (a "bit bucket") and returns EOF when read. Used to silence noisy commands, suppress error messages, or empty files (`> /dev/null` cat creates a 0-byte file). Common pattern: `command > /dev/null 2>&1` — run completely silently (no output, no error messages).
