<<comment

You’re given an access.log with timestamps and HTTP status codes.
- Task
    - Detect if 5xx errors exceed 50 requests in any 1-minute window
    - Print: ALERT: High error rate at 2026-01-15 14:32

comment

#!/bin/bash

file="./access.log"



