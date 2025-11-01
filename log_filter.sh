#!/usr/bin/env bash

# Author: Shaikh Sufiyan
# Title: Log Filter Script
# Description: A script to create a backup of log files with proper logging and error handling.
# Version: 1.0.2
# Note:
#   - Ensure that the script is executed with appropriate permissions to access a file
 

read -rp "Enter full path of a log file: " usrpath

# check if path is exists or not
[[ -z "${usrpath}" ]] && { echo "Error! cannot be empty!"; exit 1;}
[[ -f "${usrpath}" ]] || { echo "Error! file not found: $usrpath"; exit 1;}
[[ -r "${usrpath}" ]] || { echo "Error! file not readable"; exit 1;}

# prevent Dos attack
max_file_size=$((100 * 1024 * 1024)) # 100 mb limit 
file_size=$(stat -f%z "usrpath" 2>/dev/null || stat -c%s "userpath" 2>/dev/null)
((file_size > max_file_size)) && { echo "Error! file too large(max size 100MB)"; exit 1;}

# common errors
filter=("error" "fail" "failed" "denied" "oom" "segfault" "panic" "disk full" "refused" "unauthorized")

# read log file line by line
found_any=false
for pattern in "${filter[@]}"; do
    if matches=$(grep -in "$pattern" "$usrpath" 2>/dev/null); then
        found_any=true
        echo "Found '$pattern':"
        echo "$matches" | head -n 5  # Limit output
        echo
    fi
done

$found_any || echo "No errors found"
echo "Scan complete."

