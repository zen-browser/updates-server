#!/bin/bash

binary_name="zen"
config_directory="/etc/1password"
allowed_browsers_file="$config_directory/custom_allowed_browsers"
config_backup_directory=""
directory_created=false

# Rollback
rollback() {
    echo "Rolling back changes..."

    if [ "$directory_created" = true ]; then
        sudo rm -rv "$config_directory"
    elif [ -n "$config_backup_directory" ] && [ -d "$config_backup_directory" ]; then
        echo "Restoring backup of 1Password config directory at \"$config_directory\" from \"$config_backup_directory\""
        sudo rm -rv "$config_directory"
        sudo mv -v "$config_backup_directory" "$config_directory"
        echo "Rollback complete..."
    else
        echo "Nothing to rollback! Exiting..."
    fi

    exit 1
}

echo -e "Welcome, just chill and we'll configure the rest for you!\n"

sleep 1

# Backup
if [ -d "$config_directory" ]; then
    config_backup_directory=$(mktemp -d /tmp/1password_config_backup_XXXXXX)
    echo "Backing up \"$config_directory\" to \"$config_backup_directory\"..."
    sudo cp -r "$config_directory/." "$config_backup_directory"
    echo -e "\nNOTE: You can restore your previous 1Password configuration from \"$config_backup_directory\", till your /tmp directory is cleared (usually at the next boot)"
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
    else
        echo "Created config directory at \"$config_directory\""
    fi
    directory_created=true
else
    echo "1Password Config directory already exists!"
fi

# Check file
if [ ! -f "$allowed_browsers_file" ]; then
    echo "Creating 1Password Custom Allowed Browsers file and adding Zen to it..."
    echo "$binary_name" | sudo tee -a "$allowed_browsers_file" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to append to the custom allowed browsers file at \"$allowed_browsers_file\"."
        rollback
    fi
else
    echo "Custom Allowed Browsers file already exists!"
    
    # Check if Zen is already whitelisted or not
    if ! grep -Fxq "$binary_name" "$allowed_browsers_file"; then
        echo "Adding Zen to 1Password Custom Allowed Browsers file..."
        echo "$binary_name" | sudo tee -a "$allowed_browsers_file" > /dev/null
        if [ $? -ne 0 ]; then
            echo "Failed to append to the custom allowed browsers file at \"$allowed_browsers_file\"."
            rollback
        fi
    else
        echo "Zen is already whitelisted in the custom allowed browsers file"
        exit 0
    fi
fi

echo "1Password integration with Zen Browser was successful! Have fun! 🐷"
