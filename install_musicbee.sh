#!/bin/env bash

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

# OS-dependent installation
if [ "${OS}" == "Debian" ] || [ "${OS}" == "Ubuntu" ]; then
    apt install -y wine winetricks lib32-alsa-plugins lib32-libpulse lib32-openal
    # Only needed for automated installation
    apt install -y curl megatools unzip xdotool
elif [ "${OS}" == "Arch Linux" ]; then
    if [ "$(which yay)" == "" ]; then
	echo "Yay must be installed for this script to work".
	exit 0
    fi
    yay -S --noconfirm  wine-staging winetricks lib32-alsa-plugins lib32-libpulse lib32-openal
    # Only needed for automated installation
    yay -S --noconfirm curl mego unzip xdotool
else
    echo "The recognized OS (${OS}) is not currently supported."
    exit 0
fi

cd /tmp # Set working directory

# OS-dependent MEGA download
MEGA_URL=$(curl -s https://getmusicbee.com/downloads/ | grep -m 1 -o https://mega.* | awk '/(https:\/\/mega.*)/ {print substr($1, 1, length($1)-1)}') # Get latest musicbee download link
if [ "${OS}" == "Debian" ] || [ "${OS}" == "Ubuntu"]; then
    mega-get "${MEGA_URL}"
elif [ "${OS}" == "Arch Linux" ]; then
    mego "${MEGA_URL}"
fi
unzip -o /tmp/MusicBeeSetup*.zip # Extract it

echo Installing wine...
export WINEPREFIX=${HOME}/.wine32 
export WINEARCH=win32
winecfg &
sleep 5
xdotool windowactivate --sync $(xdotool search --name Wine\ Mono) key Ctrl+Tab 		# Cancel on installing mono
xdotool windowactivate --sync $(xdotool search --name Wine\ Mono) key Ctrl+Return 	# OK on installing mono
sleep 10									
xdotool windowactivate --sync $(xdotool search --name Wine) key Ctrl+Return 		# OK on finishing winecfg

echo Set windows version to Windows10
winetricks win10 

echo Install dependencies
winetricks -q dotnet48 xmllite gdiplus

echo Install MusicBee
wine /tmp/MusicBeeSetup*.exe &
sleep 2 									
xdotool windowactivate --sync $(xdotool search --name MusicBee) key Ctrl+Return 
xdotool windowactivate --sync $(xdotool search --name MusicBee) key Ctrl+Return 
xdotool windowactivate --sync $(xdotool search --name MusicBee) key Ctrl+Return 
sleep 6 									
xdotool windowactivate --sync $(xdotool search --name MusicBee) key Ctrl+Return 

echo "alias musicbee='WINEPREFIX=${HOME}/.wine32 wine ${HOME}/.wine32/drive_c/Program\ Files/MusicBee/MusicBee.exe'" >> ~/.bashrc # Set musicbee alias

# OS-dependent cleanup
if [ "${OS}" == "Debian" ] || [ "${OS}" == "Ubuntu" ]; then
    apt remove -y megatools xdotool
elif [ "${OS}" == "Arch Linux" ]; then
    yay -R --noconfirm mego xdotool
fi

exit 0
