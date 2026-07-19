#!/bin/bash
#
# Log rate spike detector
# Task: Detect if 5xx errors exceed 50 requests in any 1-minute window
# Print: ALERT: High error rate at 2026-01-15 14:32

file="./access.log"
threshold=50

declare -A window_counts

# Read log line by line and count 5xx errors per minute
while IFS= read -r line; do
    # Extract timestamp (assume format: [2026-01-15 14:32:45] ... 503 ...)
    timestamp=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}')
    status=$(echo "$line" | grep -oE ' [0-9]{3} ' | tr -d ' ')

    if [[ -z "$timestamp" || -z "$status" ]]; then
        continue
    fi

    if [[ "$status" =~ ^5[0-9]{2}$ ]]; then
        window_counts["$timestamp"]=$((${window_counts["$timestamp"]:-0} + 1))
    fi
done < "$file"

# Check each window
found=0
for minute in "${!window_counts[@]}"; do
    count=${window_counts[$minute]}
    if [[ $count -gt $threshold ]]; then
        echo "ALERT: High error rate at $minute (${count} 5xx errors)"
        found=1
    fi
done

if [[ $found -eq 0 ]]; then
    echo "No spike detected. All windows below threshold (${threshold})."
fi
