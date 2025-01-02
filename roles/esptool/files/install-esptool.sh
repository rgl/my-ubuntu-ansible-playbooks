#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/esptool ]; then
    # e.g.:
    #   esptool.py v4.8.1
    #   4.8.1
    actual_version="$(/usr/local/bin/esptool version | tail -1)"
    if [ "$actual_version" == "$ESPTOOL_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://github.com/espressif/esptool/releases/download/v${ESPTOOL_VERSION}/esptool-v${ESPTOOL_VERSION}-linux-amd64.zip"
t="$(mktemp -q -d --suffix=.esptool)"
wget -qO "$t/esptool.zip" "$url"
unzip -j "$t/esptool.zip" -d "$t"
install -m 755 "$t/esptool" /usr/local/bin
rm -rf "$t"
