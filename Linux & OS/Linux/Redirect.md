# File Descriptors and Redirection

> Every Linux process has three standard file descriptors by default. Redirection controls where a process reads from and writes to — essential for logging, automation, and building shell pipelines.

---

## File Descriptors

```
File Descriptor  Name    Default destination
─────────────────────────────────────────────
0                stdin   Keyboard (terminal input)
1                stdout  Terminal (normal output)
2                stderr  Terminal (error output)

A file descriptor is an integer that represents an open file.
The kernel uses FDs to track open files, sockets, pipes, devices.
e.g., open("/etc/hosts") → returns fd=3 (first available after 0,1,2)
```

---

## Redirection Operators

```bash
# Stdout redirection:
>      overwrite stdout to file        (e.g., ls > files.txt)
>>     append stdout to file           (e.g., echo "line" >> log.txt)

# Stderr redirection:
2>     overwrite stderr to file        (e.g., command 2> errors.log)
2>>    append stderr to file

# Combined:
&>     redirect both stdout and stderr to file
&>>    append both stdout and stderr to file

# Input:
<      use file as stdin               (e.g., mysql < schema.sql)
<<EOF  heredoc — multiline stdin       (inline string until EOF marker)
```

---

## Practical Redirection Examples

```bash
# Redirect stdout to file (overwrites):
ls -la > files.txt

# Append stdout to file:
echo "new line" >> log.txt

# Redirect only errors — discard them:
command 2>/dev/null

# Redirect both stdout and stderr to same file:
command > all.log 2>&1
# OR shorthand:
command &> all.log

# Append both stdout and stderr:
command &>> all.log

# Use file as stdin:
mysql -u root -p mydb < schema.sql

# Heredoc — multiline input redirection:
cat <<EOF > config.yaml
server: localhost
port: 8080
debug: true
EOF

# Heredoc for remote commands over SSH (e.g., run multi-command script):
ssh user@server <<EOF
sudo systemctl restart nginx
sudo journalctl -n 50 nginx
EOF
```

---

## Pipelines

```bash
# Pipe stdout of one command to stdin of next:
cat /var/log/syslog | grep "ERROR" | tail -20

# Pipe stderr through pipeline — merge stderr into stdout first:
command 2>&1 | grep "error"

# tee — write to file AND pass through to stdout simultaneously:
command | tee output.txt | grep "important"

# Save stdout while still seeing it in terminal:
long-running-script | tee script.log
```

---

## /dev/null — The Trash

```bash
# Discard all output (run command silently):
noisy-command > /dev/null 2>&1

# Discard only stderr, keep stdout visible:
command 2>/dev/null

# Empty a file in-place (truncate):
> file.txt
# or:
cat /dev/null > file.txt
```

---

## Process Substitution

```bash
# diff two command outputs directly — no temp files needed:
diff <(ls dir1) <(ls dir2)

# Feed command output as a file argument:
while read line; do echo "→ $line"; done < <(cat hosts.txt)
```

---

## stdout vs stderr vs stdin — When to Use Which

| Stream | FD | Use Case | Example |
|--------|-----|----------|---------|
| stdout | 1 | Normal program output | `echo "done"`, `ls` results |
| stderr | 2 | Error messages, warnings, logs | `echo "Error: file not found" >&2` |
| stdin | 0 | Interactive input or piped data | `read name`, `cat < file` |

**Best practice for scripts:** always write error messages to stderr:
```bash
echo "Error: config file missing" >&2   # write to stderr
exit 1
```
This way, when users pipe your script's output to another command, only real data goes through the pipe — errors stay on the terminal.

---

## Interview Q&A

**Q: What is the difference between `2>&1` and `&>`?**
`2>&1` redirects file descriptor 2 (stderr) to wherever fd 1 (stdout) currently points. Order matters: `> file 2>&1` works correctly (stdout→file, then stderr→where stdout points = file); `2>&1 > file` does not (stderr→old stdout = terminal, then stdout→file). `&>` is bash shorthand that redirects both to a file correctly regardless of order — it's equivalent to `> file 2>&1`.

**Q: What does `/dev/null` do, and when would you use it?**
`/dev/null` is a virtual device that discards everything written to it and returns EOF when read — it's a "bit bucket." Use it to silence noisy commands (e.g., `command > /dev/null 2>&1` runs completely silently), discard only error output while keeping stdout visible (`command 2>/dev/null`), or empty a file in-place (`> file.txt`). In scripts, silencing expected errors is common — e.g., `mkdir -p /tmp/dir 2>/dev/null` ignores "directory already exists" errors.
