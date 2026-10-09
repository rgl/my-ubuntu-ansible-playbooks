#!/bin/bash
set -euxo pipefail

# bail when already installed.
meta_path='/usr/local/bin/ytdownloader.meta.json'
if [ -r "$meta_path" ]; then
    actual_version="$(jq -r .version "$meta_path")"
    if [ "$actual_version" == "$YTDOWNLOADER_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
# see YTDownloader_Linux.AppImage --appimage-help
url="https://github.com/aandrew-me/ytDownloader/releases/download/v${YTDOWNLOADER_VERSION}/YTDownloader_Linux.AppImage"
t="$(mktemp -q -d --suffix=.ytdownloader)"
wget -qO "$t/ytdownloader" "$url"
pushd "$t"
chmod +x ytdownloader
./ytdownloader --appimage-extract usr/share/icons/hicolor/256x256/apps/ytdownloader.png
install \
    squashfs-root/usr/share/icons/hicolor/256x256/apps/ytdownloader.png \
    /usr/share/icons/hicolor/256x256/apps/ytdownloader.png
popd
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
install -m 755 "$t/ytdownloader" /usr/local/bin
jq -n \
    --arg version "$YTDOWNLOADER_VERSION" \
    '{version: $version}' \
    >"$meta_path"
rm -rf "$t"
