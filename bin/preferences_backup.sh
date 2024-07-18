#!/bin/bash

log_message() {
	echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$log_file"
}

# Function to check if plist file is empty
is_plist_empty() {
	plist_file=$1
	if defaults read "$plist_file" &>/dev/null; then
		return 1
	else
		return 0
	fi
}

# Get the current timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Main directory to store backups
main_backup_dir="$HOME/PreferencesBackup"
mkdir -p "$main_backup_dir"

# Directory to store the current backup with timestamp
current_backup_dir="$main_backup_dir/Backup_$timestamp"
mkdir -p "$current_backup_dir"

# Log file
log_file="$current_backup_dir/backup_and_reset.log"

# Get the list of all domains
domains=$(defaults domains)

# Convert the list to an array
IFS=', ' read -r -a domainArray <<<"$domains"

# Confirmation prompt
read -p "Are you sure you want to backup all the preferences? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
	log_message "Operation cancelled by user."
	exit 1
fi

# Loop through each domain and back up preferences
for domain in "${domainArray[@]}"; do
	plist_file="$HOME/Library/Preferences/$domain.plist"
	if [ -f "$plist_file" ]; then
		log_message "Backing up preferences for domain: $domain"
		cp "$plist_file" "$current_backup_dir/$(basename $plist_file)"
	else
		log_message "No preferences file found for domain: $domain, skipping backup and reset."
	fi
done

log_message "Preferences have been backed up to $current_backup_dir and reset."
