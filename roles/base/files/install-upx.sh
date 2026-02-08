#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/upx ]; then
    # e.g. upx 5.1.0
    actual_version="$(/usr/local/bin/upx --version | perl -ne '/upx (\d+(\.\d+)+)/ && print $1')"
    if [ "$actual_version" == "$UPX_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
u="https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz"
t="$(mktemp -q -d --suffix=.upx)"
wget -qO- "$u" | tar xJ -C "$t" --strip-components 1
install -m 755 "$t/upx" /usr/local/bin/upx
rm -rf "$t"

# give it a try.
/usr/local/bin/upx --version
