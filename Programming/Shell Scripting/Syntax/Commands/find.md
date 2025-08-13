# find command  <find /path/ flags>
1. `-type <>`
    - f -> regular file
    - d -> dir
    - l -> symbolic link
    - c -> character device 
    - b -> block device
    - find . -type f

2. `-name <>`
    - Case-sensitive name match
    - find . -name "*.log"
3. `-iname <>`
    - Case-insensitive name match
4. `-regex <>`
5. `-path <>`
    - Match full path
    - find . -path "./dir/*.log"
6. `-ipath <>`
    - Case-insensitive version of -path

7. `-mtime N`
    - Modified N days ago
    - -mtime +7 = older than 7 days
8. `-atime N`
    - Last accessed N days ago
9. `-mmin N`
    - Modified N minutes ago
    - -mmin -30 = modified in last 30 min
10. `-newer file`
    - Modified more recently than another file
    - -newer ref.txt

11. `-size <>`
    - c - byte, M - MB, k - KB
    - + -> greater than, - -> less than 
    - +20M or -20M

12. `-user <username>`
13. `-group <groupname>`
14. `-perm 644`
15. `-perm -u+x` 
    - Files where user has execute permission

16. `-a`
    - AND operator 
    - find . -type f -name "*.sh" -a -executable

17. `-o`
    - OR operator 
    - find . -name "*.log" -o -name "*.txt"
18. `!`
    - find . ! -name "*.txt"

19. `-print`
    - Print the result (default)
    - find . -type f -print

20 `-exec CMD {} \;`
    - Run a command on each result
    - 	find . -name "*.log" -exec rm {} \;

21. `-exec CMD {} +`
    - Run a command on many files at once
    - find . -type f -exec ls -lh {} +

22. `-delete`
    - Delete found files or directories (careful!)
    - find . -name "*.tmp" -delete

23. `-ok CMD {} \;`
    - Like -exec, but asks for confirmation
    - find . -name "*.conf" -ok rm {} \;

24. `-maxdepth N`
    - Do not go deeper than N levels
    - find . -maxdepth 1 -type f
25. `-mindepth N`
    - Only match files N or more levels deep
    - find . -mindepth 2 -name "*.log"
26. `-prune`
    - Skip directories from traversal
    - find . -path "./node_modules" -prune -o -print
