# /bin/bash

# Script Name: backup_reset_restore_preferences.sh
# Description: Backs up all macOS user preferences to a timestamped directory
# within a main PreferencesBackup directory,
# resets all preferences to their default state, and then runs a user-defined
# script to apply specific settings.

# Function to log messages
log_message() {
	echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$log_file"
}

# Function to copy a file and preserve permissions
copy_with_permissions() {
	src=$1
	dst=$2
	cp "$src" "$dst"
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
read -p "Are you sure you want to reset all preferences? This action cannot be undone. (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
	log_message "Operation cancelled by user."
	exit 1
fi

# Loop through each domain and back up and reset preferences
for domain in "${domainArray[@]}"; do
	plist_file="$HOME/Library/Preferences/$domain.plist"

	if [ -f "$plist_file" ]; then
		if ! is_plist_empty "$plist_file"; then
			log_message "Backing up preferences for domain: $domain"
			copy_with_permissions "$plist_file" "$current_backup_dir/$(basename $plist_file)"
			log_message "Resetting preferences for domain: $domain"
			defaults delete "$domain" || log_message "Failed to delete preferences for $domain"
		else
			log_message "Plist file for domain: $domain is empty, skipping backup and reset."
		fi
	else
		log_message "No preferences file found for domain: $domain, skipping backup and reset."
	fi
done

log_message "Preferences have been backed up to $current_backup_dir and reset."

# Run user-defined script to apply specific settings
user_defined_script="$HOME/code/dotfiles/bin/setup_dotfiles.sh"
if [ -f "$user_defined_script" ]; then
	log_message "Running user-defined script to apply specific settings"
	bash "$user_defined_script" || log_message "Failed to run user-defined script"
else
	log_message "User-defined script not found"
fi

log_message "All specified preferences have been reset to their default state and specific settings have been applied."
