#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -r /usr/local/share/applications/rpi-imager.desktop ]; then
    actual_version="$(perl -ne '/^# RPI_IMAGER_VERSION: (.+)/ && print $1' /usr/local/share/applications/rpi-imager.desktop)"
    if [ "$actual_version" == "$RPI_IMAGER_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://github.com/raspberrypi/rpi-imager/releases/download/v${RPI_IMAGER_VERSION}/Raspberry_Pi_Imager-${RPI_IMAGER_VERSION}-x86_64.AppImage"
t="$(mktemp -q -d --suffix=.rpi-imager)"
pushd "$t"
wget -qO rpi-imager "$url"
chmod +x rpi-imager
# NB use rpi-imager --appimage-help to known what AppImage options are available.
./rpi-imager --appimage-extract usr/share/icons/hicolor/128x128/apps/rpi-imager.png
cat >/usr/local/share/applications/rpi-imager.desktop <<EOF
# RPI_IMAGER_VERSION: $RPI_IMAGER_VERSION
[Desktop Entry]
Type=Application
Version=1.5
Name=Raspberry Pi Imager
Comment=Raspberry Pi Imager
Icon=/usr/local/share/icons/hicolor/128x128/apps/rpi-imager.png
Exec=rpi-imager --disable-telemetry %F
Categories=Utility
StartupNotify=false
EOF
cp -r squashfs-root/usr/* /usr/local
install -m 755 rpi-imager /usr/local/bin
popd
rm -rf "$t"
