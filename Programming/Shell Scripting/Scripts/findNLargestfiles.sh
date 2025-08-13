<<comment
Write a script to list the top 10 largest files in a given directory.
comment


#!/bin/bash

dir=../../

find $dir -type f  -exec du -h {} + | sort -rh | head -5


<<comment
du -h  -> Shows sizes of directories only (not individual files)
du -ah -> Shows sizes of all files and directories
du -sh * -> Shows total size of each top-level item (silent mode)


-exec du -h {} +

-exec: For each file found, execute a command (in this case, du -h).

du -h: Shows human-readable disk usage for each file.

{}: Placeholder for the current file found.

+: Tells find to pass multiple files at once to du (faster than running du for each file individually).

comment

