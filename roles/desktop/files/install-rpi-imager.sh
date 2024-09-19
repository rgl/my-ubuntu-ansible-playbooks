#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -r /usr/local/bin/rpi-imager ]; then
    # NB rpi-imager.AppImage --version does not work from an ssh session, so
    #    we have to work around that, by extracting the
    #    org.raspberrypi.rpi-imager.desktop file from the AppImage, then the
    #    X-AppImage-Version property value.
    # e.g. X-AppImage-Version=1.9.0
    actual_version="$(7z x -so /usr/local/bin/rpi-imager '*.desktop' | perl -ne '/^X-AppImage-Version=(.+)/ && print $1')"
    if [ "$actual_version" == "$RPI_IMAGER_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://github.com/raspberrypi/rpi-imager/releases/download/v${RPI_IMAGER_VERSION}/Raspberry_Pi_Imager-${RPI_IMAGER_VERSION}-x86_64.AppImage"
t="$(mktemp -q -d --suffix=.rpi-imager)"
wget -qO "$t/rpi-imager" "$url"
7z x "$t/rpi-imager" "-o$t" usr/share/icons/hicolor/128x128/apps/rpi-imager.png
cat >/usr/local/share/applications/rpi-imager.desktop <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Raspberry Pi Imager
Comment=Raspberry Pi Imager
Icon=/usr/local/share/icons/hicolor/128x128/apps/rpi-imager.png
Exec=rpi-imager --disable-telemetry %F
Categories=Utility
StartupNotify=false
EOF
cp -r "$t/usr/"* /usr/local
install -m 755 "$t/rpi-imager" /usr/local/bin
rm -rf "$t"
