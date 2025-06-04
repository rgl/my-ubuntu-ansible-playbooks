#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -r /usr/local/bin/ytdownloader ]; then
    # NB ytdownloader.AppImage --version does not work from an ssh session, so
    #    we have to work around that, by extracting the ytdownloader.desktop
    #    file from the AppImage, then the X-AppImage-Version property value.
    # e.g. X-AppImage-Version=3.19.1
    actual_version="$(7z x -so /usr/local/bin/ytdownloader '*.desktop' | perl -ne '/^X-AppImage-Version=(.+)/ && print $1')"
    if [ "$actual_version" == "$YTDOWNLOADER_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://github.com/aandrew-me/ytDownloader/releases/download/v${YTDOWNLOADER_VERSION}/YTDownloader_Linux.AppImage"
t="$(mktemp -q -d --suffix=.ytdownloader)"
wget -qO "$t/ytdownloader" "$url"
7z x "$t/ytdownloader" "-o$t" usr/share/icons/hicolor/256x256/apps/ytdownloader.png
cat >/usr/local/share/applications/ytdownloader.desktop <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=ytdownloader
Comment=ytdownloader
Icon=/usr/local/share/icons/hicolor/256x256/apps/ytdownloader.png
Exec=ytdownloader %F
Categories=Utility
StartupNotify=false
EOF
cp -r "$t/usr/"* /usr/local
install -m 755 "$t/ytdownloader" /usr/local/bin
rm -rf "$t"
