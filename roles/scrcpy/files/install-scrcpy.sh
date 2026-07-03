#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /opt/scrcpy/scrcpy ]; then
    # e.g. scrcpy 4.0 <https://github.com/Genymobile/scrcpy>
    actual_version="$(/opt/scrcpy/scrcpy --version | perl -ne '/^scrcpy (.+?) / && print $1')"
    if [ "$actual_version" == "$SCRCPY_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
rm -rf /opt/scrcpy
install -d /opt/scrcpy
wget -qO- "https://github.com/Genymobile/scrcpy/releases/download/v${SCRCPY_VERSION}/scrcpy-linux-x86_64-v${SCRCPY_VERSION}.tar.gz" \
    | tar xz -C /opt/scrcpy --strip-components 1
