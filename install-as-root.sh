#!/bin/bash

set -euo pipefail

os_arch=$(uname -m)
app_name=zen
literal_name_of_installation_directory="src"
universal_path_for_installation_directory="/usr/local/$literal_name_of_installation_directory"
app_installation_directory="$universal_path_for_installation_directory/zen"
official_package_location="" # Placeholder for download URL, to be set later
open_tar_application_data_location="zen"
root_bin_path="/usr/bin"
root_application_path="/usr/share/applications"
app_bin_in_root_bin="$root_bin_path/$app_name"
desktop_in_applications="$root_application_path/$app_name.desktop"
icon_path="$app_installation_directory/browser/chrome/icons/default/default128.png"
executable_path=$app_installation_directory/zen

install() {
  echo -e "We're installing Zen, just chill and wait for the installation to complete!\n"

  # Set the official package download URL
  determinePackage "$@"

  echo "Downloading the latest package"
  tar_location=$(mktemp /tmp/zen.XXXXXX.tar.xz)
  curl -L --progress-bar -o $tar_location $official_package_location

  echo "Extracting Zen Browser..."
  tar -xvJf $tar_location

  echo "Untarred successfully!"

  echo "Checking to see if an older installation exists"
  remove

  if [ ! -d $universal_path_for_installation_directory ]; then
    echo "Creating the $universal_path_for_installation_directory directory for installation"
    mkdir $universal_path_for_installation_directory
  fi

  mv $open_tar_application_data_location $app_installation_directory

  echo "Zen successfully moved to your safe place!"

  rm $tar_location

  if [ ! -d $root_bin_path ]; then
    echo "$root_bin_path not found, creating it for you"
    mkdir $root_bin_path
  fi

  touch $app_bin_in_root_bin
  chmod u+x $app_bin_in_root_bin
  echo "#!/bin/bash
  $executable_path" >> $app_bin_in_root_bin

  echo "Created executable for your \$PATH if you ever need"

  if [ ! -d $root_application_path ]; then
    echo "Creating the $root_application_path directory for desktop file"
    mkdir $root_application_path
  fi


  cat << EOF > $desktop_in_applications
[Desktop Entry]
Name=Zen Browser
Comment=Experience tranquillity while browsing the web without people tracking you!
Keywords=web;browser;internet
Exec=$executable_path %u
Icon=$icon_path
Terminal=false
StartupNotify=true
StartupWMClass=zen
NoDisplay=false
Type=Application
MimeType=text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;text/mml;x-scheme-handler/http;x-scheme-handler/https;
Categories=Network;WebBrowser;
Actions=new-window;new-private-window;profile-manager-window;

[Desktop Action new-window]
Name=Open a New Window
Exec=$executable_path --new-window %u

[Desktop Action new-private-window]
Name=Open a New Private Window
Exec=$executable_path --private-window %u

[Desktop Action profile-manager-window]
Name=Open the Profile Manager
Exec=$executable_path --ProfileManager
EOF

  echo "Created desktop entry successfully"
  echo "Installation is successful"
  echo "Done, and done, have fun! 🐷"

  exit 0
}

cleanup() {
  echo -e "\n\nCleaning up...\n"
  if [ -f "${tar_location:-}" ]; then
    echo "Removing temporary tarball..."
    rm -f "${tar_location:-}"
  fi
  if [ -d "$open_tar_application_data_location" ]; then
    echo "Removing incomplete application directory..."
    rm -rf "$open_tar_application_data_location"
  fi
  echo "If Zen Browser was partially installed, please run the script again to install/update/uninstall."
  echo "Exiting gracefully..."
  exit 1
}

determinePackage() {
  case "$os_arch" in
      x86_64) echo "64-bit (Intel/AMD) architecture identified!" ;;
      aarch64|arm64)
      echo "64-bit ARM architecture identified!"
      os_arch="aarch64" ;;
      *)
      echo "Zen doesn't support this architecture: $os_arch"
      exit 1 ;;
  esac
  
  if [ "${1:-}" == "--twilight" ]; then
    official_package_location="https://github.com/zen-browser/desktop/releases/download/twilight/zen.linux-$os_arch.tar.xz"
    echo "You're currently in Twilight mode, this means you're downloading the latest experimental features and updates."
  else
    official_package_location="https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-$os_arch.tar.xz"
  fi
}

remove() {
  if [ -f "$app_bin_in_root_bin" ]; then
    echo "Old bin file detected, removing..."
    rm "$app_bin_in_root_bin"
  fi

  if [ -d "$app_installation_directory" ]; then
    echo "Old app files are found, removing..."
    rm -rf "$app_installation_directory"
  fi

  if [ -f "$desktop_in_applications" ]; then
    echo "Old desktop files are found, removing..."
    rm "$desktop_in_applications"
  fi
}

uninstall() {
  echo -n "WARN: This will remove Zen Browser from your system. Do you wish to proceed? [y/N]: "
  read -rn1 confirm < /dev/tty
  echo
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Nice save! We didn't remove Zen from your system."
    echo "Exiting..."
    exit 0
  fi
  echo "Uninstalling Zen Browser..."
  remove
  echo "Keeping your profile data will let you continue where you left off if you reinstall Zen later."
  echo -n "Do you want to delete your Zen Profiles? This will remove all your bookmarks, history, and settings. [y/N]: "
  read -rn1 remove_profile < /dev/tty
  echo
  if [[ "$remove_profile" =~ ^[Yy]$ ]]; then
    echo "Removing Zen Profiles data..."
    rm -rf "$HOME/.zen"
  else
    echo "Keeping Zen Profiles data..."
  fi
  echo "Zen Browser has been uninstalled."
  exit 0
}

trap cleanup SIGINT SIGTERM SIGHUP

# Check OS
if [[ "$(uname)" != "Linux" ]]; then
    echo "This script is only for Linux."
    echo "Visit https://github.com/zen-browser/desktop#-installation to learn more about supported operating systems."
    exit 1
fi

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires superuser permissions. Please re-run as root."
    exit 1
fi

echo -e "Welcome to Zen tarball installer!\n"

sleep 1

echo "What would you like to do?"
echo "1) Install/Update Zen Browser"
echo "2) Uninstall Zen Browser"
echo "3) Exit"
echo -en "\nEnter your choice [1/2/3]: "
read -rn1 choice < /dev/tty
echo

case $choice in
  1)
    install "$@"
    ;;
  2)
    uninstall
    ;;
  3)
    echo "Exiting... Bye! 🐷"
    exit 0
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
