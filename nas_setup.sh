#!/bin/bash

###
### @author c4vxl
### @website https://c4vxl.de
###
### This script enables users to set up a Network Attached Storage (NAS) system on their Linux machine effortlessly. The script utilizes the Samba library for sharing the files and folders.
###


# Default values
LOG_DIR="/etc/NAS"
LOG_FILE="$LOG_DIR/log.txt"
SAMBA_CONFIG="/etc/samba/smb.conf"
NAS_GROUP="NAS_user"

# Function to create log file
create_logfile() {
    mkdir -p "$LOG_DIR"

    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    else
        rm "$LOG_FILE"
        touch "$LOG_FILE"
    fi

    echo "Log file created: $LOG_FILE"
}

# Function to add text to log file
addto_log() {
    local text="$1"

    # Print to console
    echo "$text"

    # Append to log file
    echo "$text" >> "$LOG_FILE"
}

# Function to create an account
create_account() {
    local user="$1"
    local password="$2"

    # Create the user with the password
    if ! id "$user" &>/dev/null; then
        # User does not exist, create the user with a password
        sudo useradd "$user" -m -s /bin/bash -p $(echo "$password" | openssl passwd -1 -stdin)
        addto_log "Created User $user!"
    else
        addto_log "Failed to create User $user, because it already exists"
    fi

    # Set the Samba password for the user
    echo -e "$password\n$password" | sudo smbpasswd -a "$user"

    # Add user to NAS Group
    sudo usermod -a -G "$NAS_GROUP" "$user"
}

# Function to share a path
share_path() {
    local share_name="$1"
    local path="$2"
    local writable="$3"
    local browsable="$4"
    local public="$5"

    addto_log "Generating Share Config..."
    addto_log """
        CONFIGURATION:
         - Name: $share_name
         - Path to share: $path
         - Public: $public
         - Writable: $writable
         - Browsable: $browsable
    """

    echo "[$share_name]">>"$SAMBA_CONFIG"
    echo "  path = $path">>"$SAMBA_CONFIG"
    echo "  valid users = +$NAS_GROUP">>"$SAMBA_CONFIG"
    echo "  force group = $NAS_GROUP">>"$SAMBA_CONFIG"
    echo "  available = yes">>"$SAMBA_CONFIG"
    echo "  writeable = $writable">>"$SAMBA_CONFIG"
    echo "  browsable = $browsable">>"$SAMBA_CONFIG"
    echo "  public = $public">>"$SAMBA_CONFIG"
    echo "  create mask = 0660">>"$SAMBA_CONFIG"
    echo "  directory mask = 0770">>"$SAMBA_CONFIG"

    addto_log "Added Configuration to Samba Config."
}

# Function to display help
display_help() {
    echo "NAS Setup Script"
    echo "----------------"
    echo "This script sets up a NAS system using Samba with ease."
    echo "It allows you to configure a shared folder, create a NAS group, and add user accounts."

    echo -e "\nUsage: $0 [OPTIONS]"
    echo -e "Options:"
    echo "  -group=GROUP          Set the NAS group name (default: NAS_user)"
    echo "  -acc=USER:PASSWORD   Add a user account with the specified username and password"
    echo "  -path=PATH            Set the path to the shared folder (required)"
    echo "  -name=NAS_NAME        Set the name of the NAS (required)"
    echo "  -public=PUBLIC        Set whether the folder should be public (yes/no) (required)"
    echo "  -writable=WRITABLE    Set whether the folder should be writable (yes/no) (required)"
    echo "  -readable=READABLE    Set whether the folder should be readable (yes/no) (required)"
    echo "  -help                 Display this help message"
}

# Process command line options
while getopts ":g:a:p:n:u:w:r:h" opt; do
    case $opt in
        g)
            NAS_GROUP="$OPTARG"
            ;;
        a)
            IFS=':' read -r -a acc_info <<< "$OPTARG"
            create_account "${acc_info[0]}" "${acc_info[1]}"
            ;;
        p)
            SHARE_PATH="$OPTARG"
            ;;
        n)
            NAS_NAME="$OPTARG"
            ;;
        u)
            PUBLIC_OPTION="$OPTARG"
            case $PUBLIC_OPTION in
                y|yes)
                    PUBLIC="yes"
                    ;;
                n|no)
                    PUBLIC="no"
                    ;;
                *)
                    echo "Invalid value for -public: $PUBLIC_OPTION. Use 'yes' or 'no'."
                    exit 1
                    ;;
            esac
            ;;
        w)
            WRITABLE_OPTION="$OPTARG"
            case $WRITABLE_OPTION in
                y|yes)
                    WRITABLE="yes"
                    ;;
                n|no)
                    WRITABLE="no"
                    ;;
                *)
                    echo "Invalid value for -writable: $WRITABLE_OPTION. Use 'yes' or 'no'."
                    exit 1
                    ;;
            esac
            ;;
        r)
            READABLE_OPTION="$OPTARG"
            case $READABLE_OPTION in
                y|yes)
                    READABLE="yes"
                    ;;
                n|no)
                    READABLE="no"
                    ;;
                *)
                    echo "Invalid value for -readable: $READABLE_OPTION. Use 'yes' or 'no'."
                    exit 1
                    ;;
            esac
            ;;
        h)
            display_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# Check required arguments
if [ -z "$SHARE_PATH" ] || [ -z "$NAS_NAME" ] || [ -z "$PUBLIC" ] || [ -z "$WRITABLE" ] || [ -z "$READABLE" ]; then
    echo "Error: -path, -name, -public, -writable, and -readable are required arguments."
    exit 1
fi

# Main script starts here
clear
create_logfile

addto_log "Nas Group: $NAS_GROUP"

# Create NAS Group
addto_log "Creating NAS Group..."
sudo getent group "$NAS_GROUP" || sudo groupadd "$NAS_GROUP"
addto_log "NAS Group created!"

# Change Permissions for $SHARE_PATH
addto_log "Changing Permissions for '$SHARE_PATH'"
sudo chown