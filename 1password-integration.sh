#!/bin/bash

config_directory="/etc/1password"
allowed_browsers_file="$config_directory/custom_allowed_browsers"
config_backup_directory="/tmp/1password_config_backup_$(date +'%Y%m%d_%H%M%S')"
directory_created=false

# Rollback
rollback() {
    echo "Rolling back changes..."

    if [ "$directory_created" = true ];then
        sudo rm -rf "$config_directory"
    elif [ -d "$config_backup_directory" ]; then
        echo "Restoring backup of 1Password config directory at \"$config_directory\" from \"$config_backup_directory\""
        sudo rm -rf "$config_directory"
        sudo mv "$config_backup_directory" "$config_directory"
        echo "Rollback complete..."
    else
        echo "Nothing to rollback! Exiting..."
    fi

    exit 1
}

# Backup
if [ -d "$config_directory" ]; then
    echo "Backing up \"$config_directory\" to \"$config_backup_directory\"..."
    sudo cp -r "$config_directory" "$config_backup_directory"
    if [ $? -ne 0 ]; then
        echo "Failed to backup \"$config_directory\". Exiting..."
        exit 1
    fi
fi

# Check directory
if [ ! -d "$config_directory" ]; then
    sudo mkdir -p "$config_directory"
    if [ $? -ne 0 ]; then
        echo "Failed to create config directory at \"$config_directory\"."
        rollback
    fi
    directory_created=true
else
    echo "1Password Config directory already exists!"
fi

# Check file
if [ ! -f "$allowed_browsers_file" ]; then
    echo "zen" | sudo tee -a "$allowed_browsers_file" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to append to the custom allowed browsers file at \"$allowed_browsers_file\"."
        rollback
    fi
else
    echo "Custom Allowed Browsers file already exists!"
    
    # Check if Zen is already whitelisted or not
    if ! grep -Fxq "zen" "$allowed_browsers_file"; then
        echo "zen" | sudo tee -a "$allowed_browsers_file" > /dev/null
        if [ $? -ne 0 ]; then
            echo "Failed to append to the custom allowed browsers file at \"$allowed_browsers_file\"."
            rollback
        fi
    else
        echo "Zen is already set as whitelisted in the custom allowed browsers file"
    fi
fi

echo "1Password integration with Zen Browser was successful! Have fun! 🐷"
