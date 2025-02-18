#!/bin/bash

set -euo pipefail

os_arch=$(uname -m)
app_name=zen
literal_name_of_installation_directory="src"
universal_path_for_installation_directory="/usr/local/$literal_name_of_installation_directory"
app_installation_directory="$universal_path_for_installation_directory/zen"
official_package_location="https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-$os_arch.tar.xz"
tar_location=$(mktemp /tmp/zen.XXXXXX.tar.xz)
open_tar_application_data_location="zen"
root_bin_path="/usr/bin"
root_application_path="/usr/share/applications"
app_bin_in_root_bin="$root_bin_path/$app_name"
desktop_in_local_applications="$root_application_path/$app_name.desktop"
icon_path="$app_installation_directory/browser/chrome/icons/default/default128.png"
executable_path=$app_installation_directory/zen

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script requires superuser permissions. Please re-run as root."
    exit 1
fi

echo -e "Welcome to Zen tarball installer, just chill and wait for the installation to complete!\n"

sleep 1

case "$os_arch" in
    x86_64) echo "64-bit (Intel/AMD) architecture identified!" ;;
    aarch64|arm64) echo "64-bit ARM architecture identified!" ;;
    *)
		echo "Zen doesn't support this architecture: $os_arch"
		exit 1 ;;
esac

echo "Downloading the latest package"
curl -L --progress-bar -o $tar_location $official_package_location
if [ $? -eq 0 ]; then
    echo OK
else
    echo "Download failed. Curl not found or not installed"
    exit
fi

echo "Extracting Zen Browser..."
tar -xvJf $tar_location

echo "Untarred successfully!"

echo "Checking to see if an older installation exists"
if [ -f "$app_bin_in_root_bin" ]; then
  echo "Old bin file detected, removing..."
  rm "$app_bin_in_root_bin"
fi

if [ -d "$app_installation_directory" ]; then
  echo "Old app files are found, removing..."
  rm -rf "$app_installation_directory"
fi

if [ -f "$desktop_in_local_applications" ]; then
  echo "Old desktop files are found, removing..."
  rm "$desktop_in_local_applications"
fi

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


touch $desktop_in_local_applications
echo "
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
" >> $desktop_in_local_applications

echo "Created desktop entry successfully"
echo "Installation is successful"
echo "Done, and done, have fun! 🐷"

exit 0
