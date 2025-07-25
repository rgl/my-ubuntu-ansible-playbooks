#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/dagger ]; then
    # e.g. dagger v0.18.14 linux/amd64
    actual_version="$(/usr/local/bin/dagger version | perl -ne '/^dagger v?(.+?) / && print $1')"
    if [ "$actual_version" == "$DAGGER_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
dagger_url="https://github.com/dagger/dagger/releases/download/v${DAGGER_VERSION}/dagger_v${DAGGER_VERSION}_linux_amd64.tar.gz"
t="$(mktemp -q -d --suffix=.dagger)"
wget -qO- "$dagger_url" | tar xzf - -C "$t" dagger
install "$t/dagger" /usr/local/bin/
rm -rf "$t"
