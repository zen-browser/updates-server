#!/bin/bash

# LICENSE:
# Done by: https://github.com/Muko-Tabi
# Twilight support added by: https://github.com/LeMoonStar
# This script is licensed under the MIT License.

set -euo pipefail
function log() {
    local RED='\033[0;31m'
    local YELLOW='\033[1;33m'
    local GREEN='\033[0;32m'
    local YELLOW_BG='\033[43m'
    local BLACK_FG='\033[30m'
    NC='\033[0m'
    if [[ "${1}" == "info" ]]; then
        printf "${GREEN}[i] ${2}${NC}\n"
    elif [[ "${1}" == "warn" ]]; then
        printf "${YELLOW}[w] ${2}${NC}\n"
    elif [[ "${1}" == "err" ]]; then
        printf "${RED}[e] ${2}${NC}\n"
    elif [[ "${1}" == "highlight" ]]; then
        printf "${YELLOW_BG}[h] ${BLACK_FG}${2}${NC}\n"
    else
        echo "WRONG SEVERITY : $1"
        exit 1
    fi
}

function log_info() { log "info" "$1"; }
function log_warn() { log "warn" "$1"; }
function log_err() { log "err" "$1"; }
function log_highlight() { log "highlight" "$1"; }

# Download URL globals
# Zen Stable
ZEN_STABLE="https://github.com/zen-browser/desktop/releases/latest/download/zen-x86_64.AppImage"
# Zen Twilight
ZEN_TWILIGHT="https://github.com/zen-browser/desktop/releases/download/twilight/zen-x86_64.AppImage"

# Filename base globals
ZEN_STABLE_NAME_BASE="ZenBrowser"
ZEN_TWILIGHT_NAME_BASE="ZenTwilight"

# Function to check if AVX2 is supported
check_avx2_support() {
    if grep -q avx2 /proc/cpuinfo; then
        return 0  # AVX2 supported
    else
        return 1  # AVX2 not supported
    fi
}

# Function to check if Zen Browser is installed
check_installation_status() {
    local app_name="$1"
    if [ -f ~/.local/share/AppImage/$app_name.AppImage ]; then
        return 0  # Zen Browser installed
    else
        return 1  # Zen Browser not installed
    fi
}

# Function to check if zsync is installed
check_zsync_installed() {
    if command -v zsync &> /dev/null; then
        return 0  # zsync is installed
    else
        return 1  # zsync is not installed
    fi
}

# Kawaii ASCII Art for the script
kawaii_art() {
    local is_twilight="$1"
    local file_base

    if [[ "$is_twilight" == "1" ]]; then
        file_base="$ZEN_TWILIGHT_NAME_BASE"
    else
        file_base="$ZEN_STABLE_NAME_BASE"
    fi

    log_info "╔════════════════════════════════════════════════════╗"
    log_info "║                                                    ║"
    log_info "║    (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧  Zen Browser Installer            ║"
    log_info "║                                                    ║"
 
    if check_installation_status "$file_base"; then
        log_info "║    Status: Zen Browser Installed                   ║"
    else
        log_info "║    Status: Zen Browser Not Installed               ║"
    fi

    if check_zsync_installed; then
        log_info "║    zsync: Installed (Needed for Updates)           ║"
    else
        log_info "║    zsync: Not Installed (Needed for Updates)       ║"
    fi

    log_info "║                                                    ║"
    log_info "╚════════════════════════════════════════════════════╝"
    log_info ""
}

# Function to download a file with unlimited retries
download_until_success() {
    local url="$1"
    local output_path="$2"
    local mode="$3"  # New parameter to indicate the mode

    while true; do
        case "$mode" in
            "zsync")
                log_info "Checking for Update..."
                ;;
            "update")
                log_info "Updating Zen Browser..."
                ;;
            "install")
                log_info "Installing Zen Browser..."
                ;;
        esac 
        if curl -# -L --connect-timeout 30 --max-time 600 "$url" -o "$output_path"; then
            case "$mode" in
                "zsync")
                    log_info "Checking for Update successfully!"
                    ;;
                "update")
                    log_info "Update completed successfully!"
                    ;;
                "install")
                    log_info "Install completed successfully!"
                    ;;
            esac
            break
        else
            case "$mode" in
                "zsync")
                    log_err "(⌣_⌣” ) Checking for Update failed, retrying..."
                    ;;
                "update")
                    log_err "(⌣_⌣” ) Update failed, retrying..."
                    ;;
                "install")
                    log_err "(⌣_⌣” ) Install failed, retrying..."
                    ;;
            esac
            sleep 5  # Optional: wait a bit before retrying
        fi
    done
}

process_appimage() {
    local appimage_path="$1"
    local app_name="$2"

    # Make AppImage executable
    chmod +x "${appimage_path}"

    # Extract all files from AppImage
    "${appimage_path}" --appimage-extract

    # Move .desktop file (from /squashfs-root only)
    desktop_file=$(find squashfs-root -maxdepth 1 -name "*.desktop" | head -n 1)
    mv "${desktop_file}" ~/.local/share/applications/${app_name}.desktop

    # Find PNG icon (from /squashfs-root only)
    icon_file=$(find squashfs-root -maxdepth 1 -name "*.png" | head -n 1)

    # Resolve symlink if the icon is a symlink
    if [ -L "${icon_file}" ]; then
        icon_file=$(readlink -f "${icon_file}")
    fi

    # Copy the icon to the icons directory
    cp "${icon_file}" ~/.local/share/icons/${app_name}.png

    # Move AppImage to final location, only if it's not already there
    if [ "${appimage_path}" != "$HOME/.local/share/AppImage/${app_name}.AppImage" ]; then
        mv "${appimage_path}" ~/.local/share/AppImage/
    fi

    # Edit .desktop file to update paths
    desktop_file=~/.local/share/applications/${app_name}.desktop
    awk -v home="$HOME" -v app_name="$app_name" '
    BEGIN { in_action = 0 }
    /^\[Desktop Action/ { in_action = 1 }
    /^Exec=/ {
        if (in_action) {
            split($0, parts, "=")
            sub(/^[^ ]+/, "", parts[2])  # Remove the first word (original command)
            print "Exec=" home "/.local/share/AppImage/" app_name ".AppImage" parts[2]
        } else {
            print "Exec=" home "/.local/share/AppImage/" app_name ".AppImage %u"
        }
        next
    }
    /^Icon=/ { print "Icon=" home "/.local/share/icons/" app_name ".png"; next }
    { print }
    ' "${desktop_file}" > "${desktop_file}.tmp" && mv "${desktop_file}.tmp" "${desktop_file}"

    # Clean up extracted files
    rm -rf squashfs-root
}

uninstall_appimage() {
    local app_name="$1"
    log_info ""
    # Remove AppImage
    log_warn "Removing Zen Browser AppImage..."
    rm -f ~/.local/share/AppImage/${app_name}.AppImage

    # Remove .desktop file
    log_warn "Removing Zen Browser .desktop file..."
    rm -f ~/.local/share/applications/${app_name}.desktop

    # Remove icon
    log_warn "Removing Zen Browser icon..."
    rm -f ~/.local/share/icons/${app_name}.png

    log_info ""
    log_info "(︶︹︺) Uninstalled ${app_name}"
}

check_for_updates() {
    local is_twilight="$1"
    local zsync_url
    local zsync_file
    local appimage_url
    local file_base

    if [[ "$is_twilight" == 1 ]]; then
        file_base="$ZEN_TWILIGHT_NAME_BASE"
    else
        file_base="$ZEN_STABLE_NAME_BASE"
    fi

    log_info ""
    

    if [[ "$is_twilight" == 1 ]]; then
        zsync_url="$ZEN_TWILIGHT.zsync"
        appimage_url="$ZEN_TWILIGHT"
    else
        zsync_url="$ZEN_STABLE.zsync"
        appimage_url="$ZEN_STABLE"
    fi

    zsync_file="${HOME}/Downloads/$file_base.AppImage.zsync"

    if check_installation_status "$file_base"; then
        log_info "Checking for updates..."
        if ! check_zsync_installed; then
            log_err "Zsync is not installed. Please install zsync to enable update functionality."
            return 1
        fi
        download_until_success "$zsync_url" "$zsync_file" "zsync"
        update_output=$(zsync -i ~/.local/share/AppImage/$file_base.AppImage -o ~/.local/share/AppImage/$file_base.AppImage "$zsync_file" 2>&1)
        if echo "$update_output" | grep -q "verifying download...checksum matches OK"; then
            log_info "(｡♥‿♥｡) Congrats! Zen Browser is up-to-date!"
        else
            echo "Updating Zen Browser..."
            download_until_success "$appimage_url" ~/.local/share/AppImage/$file_base.AppImage "update"
            process_appimage ~/.local/share/AppImage/$file_base.AppImage $file_base
            log_info "(｡♥‿♥｡) Zen Browser updated to the latest!"
        fi
        rm -f "$zsync_file"
    else
        log_err "Zen Browser is not installed!"
        main_menu
    fi
}

install_zen_browser() {
    local is_twilight="$1"
    local appimage_url
    local file_base

    if [[ "$is_twilight" == 1 ]]; then
        file_base="$ZEN_TWILIGHT_NAME_BASE"
    else
        file_base="$ZEN_STABLE_NAME_BASE"
    fi

    log_info ""

    if [[ "$is_twilight" == 1 ]]; then
        appimage_url="$ZEN_TWILIGHT"
    else
        appimage_url="$ZEN_STABLE"
    fi

    log_warn "Downloading Zen from $appimage_url"
    log_info ""
    temp_file="/tmp/$file_base.AppImage"
    download_until_success "$appimage_url" "$temp_file" "install"
    process_appimage "$temp_file" $file_base
    log_info ""
    log_info "(｡♥‿♥｡) Zen Browser installed successfully!"
    rm -f "$temp_file"
}

main_menu() {
    # Check if the script is in twilight mode.
    local is_twilight
    if [[ "$1" == "twilight" ]]; then
        is_twilight=1
        log_warn "The installer is in Twilight mode!"
    else
        is_twilight=0
    fi

    # Show kawaii ASCII art
    kawaii_art $is_twilight

    log_info "(★^O^★) What would you like to do?"
    log_info "  1) Install"
    log_info "  2) Uninstall"
    if check_zsync_installed; then
        log_info "  3) Check for Updates"
    fi
    log_info "  0) Exit"
    if check_zsync_installed; then
        read -p "Enter your choice (0-3): " main_choice
    else
        read -p "Enter your choice (0-2): " main_choice
    fi

    case $main_choice in
        1)
            install_zen_browser $is_twilight
            ;;
        2)
            if [[ "$is_twilight" == 1 ]]; then
                uninstall_appimage "$ZEN_TWILIGHT_NAME_BASE"
            else
                uninstall_appimage "$ZEN_STABLE_NAME_BASE"
            fi
            ;;
        3)
            if check_zsync_installed; then
                check_for_updates $is_twilight
            else
                log_err "(•ˋ _ ˊ•) Invalid choice. Exiting..."
                exit 1
            fi
            ;;
        0)
            log_info "(⌒‿⌒) Exiting..."
            exit 0
            ;;
        *)
            log_err "(•ˋ _ ˊ•) Invalid choice. Exiting..."
            exit 1
            ;;
    esac
}

# Create necessary directories
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/share/icons
mkdir -p ~/.local/share/AppImage

# Execute the main menu
main_menu "${1:-stable}"

# End of script
log_info ""
log_info "Thank you for using Zen Browser Installer!"
