#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/esptool ]; then
    # e.g.:
    #   esptool.py v5.0.0
    #   5.0.0
    actual_version="$(/usr/local/bin/esptool version | tail -1)"
    if [ "$actual_version" == "$ESPTOOL_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://github.com/espressif/esptool/releases/download/v${ESPTOOL_VERSION}/esptool-v${ESPTOOL_VERSION}-linux-amd64.tar.gz"
t="$(mktemp -q -d --suffix=.esptool)"
pushd "$t"
wget -qO- "$url" | tar xzf - --strip-components 1
install -m 755 esptool /usr/local/bin
popd
rm -rf "$t"
