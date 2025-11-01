#!/usr/bin/env bash 

# Author: Shaikh Sufiyan
# Description: Script to create a backup of log files.
# Version: 1.0.2

# Usage: ./<file_name.sh> <source_directory> <destination_directory>
# Note:
#   - Ensure the script is executed with appropriate permissions to access
#     the source and destination paths.
#   - logs are stored in /var/log/backup.log

set -euo pipefail

# variable definitions
readonly src="$1"
readonly dest="$2"
readonly backup="backup_$(date +%Y%m%d_%H%M).tar.gz"
readonly logs="/var/log/backup.log"

# logging function
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$logs"; }

# Source and destination validation
[[ ! -d "$src" ]] && { log "ERROR: Source directory not found"; exit 1; }
[[ ! -d "$dest" ]] && { log "ERROR: Destination directory not found"; exit 1; }

# backup process
log "Starting backup: $src -> $dest/$backup"

tar -czf "$dest/$backup" -C "$(dirname "$src")" "$(basename "$src")" 2>/dev/null && \
    log "Backup successful: $backup" || \
    { log "ERROR: Backup failed"; exit 1; }
