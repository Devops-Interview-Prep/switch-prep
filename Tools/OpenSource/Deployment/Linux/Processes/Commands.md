# `PS [OPTIONS]`

| Command           | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `ps`              | Shows processes running in the current shell           |
| `ps -e` or `-A`   | Lists **all** processes                                |
| `ps -u <user>`    | Processes belonging to a **specific user**             |
| `ps -f`           | Full format (UID, PPID, STIME, CMD)                    |
| `ps -l`           | Long format (includes priority, nice value)            |
| `ps aux`          | Show all processes in BSD format                       |
| `ps -ef`          | Show all processes in standard UNIX format             |
| `ps -T`           | Show threads of a process                              |
| `ps -p <pid>`     | Show process with specific PID                         |
| `ps --forest`     | Show tree view of process hierarchy                    |
| `ps --sort=<key>` | Sort output by a specific column (like `%cpu`, `%mem`) |


# Output 

```
  PID TTY           TIME CMD
  701 ttys001    0:07.91 /bin/zsh -il
33980 ttys004    0:01.46 -zsh
```
- TTY - terminal type
- Time - Amount of cpu used in terms of time 