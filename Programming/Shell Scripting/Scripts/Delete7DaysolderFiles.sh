<<comment
Delete .log files older than 7 days
comment

#!/bin/bash

dir=/path/

find $dir -type f -mtime +7 -name "*.logs" -exec rm -f {} +
