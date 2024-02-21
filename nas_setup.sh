#!/bin/bash

###
### @author c4vxl
### @website https://c4vxl.de
###
### This script enables users to set up a Network Attached Storage (NAS) system on their Linux machine effortlessly. The script utilizes the Samba library for sharing the files and folders.
###

# Variables
LOG_DIR="/var/log/c4NAS"
LOG_FILE="$LOG_DIR/log.txt"
SAMBA_CONFIG="/etc/samba/smb.conf"

# Function to create log file
create_logfile() {
    mkdir -p "$LOG_DIR" || { echo "Error creating log directory"; exit 1; }

    touch "$LOG_FILE" || { echo "Error creating log file"; exit 1; }

    echo "Log file created: $LOG_FILE"
}

# Function to add text to log file
addto_log() {
    local text="$1"

    echo "$text" >> "$LOG_FILE"
}

# Create log file
create_logfile

# Ask for NAS Group
read -p "Please enter the name of the Group for all NAS Accounts: " NAS_GROUP
addto_log "NAS Group: $NAS_GROUP"

# Function to create user account and set Samba password
create_account() {
    local username="$1"
    local password="$2"

    if ! id "$username" &>/dev/null; then
        sudo useradd "$username" -m -s /bin/bash -p "$(echo "$password" | openssl passwd -1 -stdin)" || { addto_log "Failed to create User $username"; return 1; }
        addto_log "Created User $username"
    else
        addto_log "User $username already exists"
    fi

    echo -e "$password\n$password" | sudo smbpasswd -a "$username"
    sudo usermod -a -G "$NAS_GROUP" "$username"
}

# Function to share a folder
share_path() {
    local share_name="$1"
    local path="$2"
    local writable="$3"
    local browsable="$4"
    local public="$5"

    cat <<EOF >> "$SAMBA_CONFIG"
[$share_name]
  path = $path
  valid users = +$NAS_GROUP
  force group = $NAS_GROUP
  available = yes
  writeable = $writable
  browsable = $browsable
  public = $public
  create mask = 0660
  directory mask = 0770
EOF

    addto_log "Added configuration for $share_name to Samba config"
}

# Main script

# Create NAS Group
addto_log "Creating NAS Group: $NAS_GROUP"
sudo getent group "$NAS_GROUP" || sudo groupadd "$NAS_GROUP" || { addto_log "Failed to create NAS Group $NAS_GROUP"; exit 1; }
addto_log "NAS Group created successfully"

# Prompt user for configuration inputs
read -p "Please enter the Path you want to share: " path
read -p "What should be the Name of the folder: " share_name
read -p "Should the folder be writable (yes/no): " writable
read -p "Should the folder be browsable (yes/no): " browsable
read -p "Should the folder be public (yes/no): " public

# Change permissions for $path
addto_log "Changing Permissions for '$path'"
sudo chown root:"$NAS_GROUP" "$path" && sudo chmod g+wrx "$path" || { addto_log "Failed to change permissions for $path"; exit 1; }
addto_log "Changed Permissions successfully"

# Share folder
addto_log "Sharing Folder..."
share_path "$share_name" "$path" "$writable" "$browsable" "$public" || { addto_log "Failed to share folder"; exit 1; }

# Ask for user accounts
while true; do
    read -p "Username: " username
    read -s -p "Password: " password
    echo
    create_account "$username" "$password"

    read -p "Would you like to add another account? (Y/N): " add_another
    case "${add_another^^}" in
        N*)
            break
            ;;
    esac
done

echo "Script execution complete."