<<comment
Create a script that monitors a directory for new files and logs their names with timestamps.
comment

#!/bin/bash

inotifywait -m "$DIR" -e create | while read path action file; do
  echo "$(date): $file was created in $path" >> new_files.log
done


<<comment
inotifywait -m: Continuously monitor (-m) a directory for file system events.

-e create: Triggers only on file creation.

while read ...: Reads each new event line and logs it.

date: Adds timestamp to log entry.

comment
