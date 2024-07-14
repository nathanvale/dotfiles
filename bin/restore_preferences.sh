#!/bin/bash

# Function to restore preferences from a backup directory.
# Parameters:
# - backup_dir: The directory containing the backup files.
# Returns:
# None
restore_preferences() {
	backup_dir=$1
	if [ -d "$backup_dir" ]; then
		for plist_file in "$backup_dir"/*.plist; do
			domain=$(basename "$plist_file" .plist)
			log_message "Restoring preferences for domain: $domain"
			copy_with_permissions "$plist_file" "$HOME/Library/Preferences/$domain.plist" || log_message "Failed to restore $domain"
		done
		log_message "Preferences have been restored from $backup_dir."
	else
		log_message "Backup directory $backup_dir does not exist."
	fi
}
