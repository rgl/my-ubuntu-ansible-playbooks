#!/bin/bash
set -euxo pipefail

# bail when already installed.
meta_path='/usr/local/bin/winbox.meta.json'
if [ -r "$meta_path" ]; then
    actual_version="$(jq -r .version "$meta_path")"
    if [ "$actual_version" == "$WINBOX_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://download.mikrotik.com/routeros/winbox/${WINBOX_VERSION}/WinBox_Linux.zip"
t="$(mktemp -q -d --suffix=.winbox)"
wget -qO "$t/WinBox_Linux.zip" "$url"
pushd "$t"
unzip WinBox_Linux.zip
convert \
    assets/img/winbox.png \
    -resize 256x256 \
    /usr/share/icons/hicolor/256x256/apps/winbox.png
popd
cat >/usr/local/share/applications/winbox.desktop <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=WinBox
Comment=winbox
Icon=/usr/local/share/icons/hicolor/256x256/apps/winbox.png
Exec=winbox
Categories=Utility
StartupNotify=false
EOF
install -m 755 "$t/WinBox" /usr/local/bin/winbox
jq -n \
    --arg version "$WINBOX_VERSION" \
    '{version: $version}' \
    >"$meta_path"
rm -rf "$t"
