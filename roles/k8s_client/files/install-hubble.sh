#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/hubble ]; then
    # e.g. hubble 0.13.2 compiled with go1.20.10 on linux/amd64
    actual_version="$(/usr/local/bin/hubble version | perl -ne '/^hubble:? v?(.+?) / && print $1')"
    if [ "$actual_version" == "$HUBBLE_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
hubble_url="https://github.com/cilium/hubble/releases/download/v${HUBBLE_VERSION}/hubble-linux-amd64.tar.gz"
t="$(mktemp -q -d --suffix=.hubble)"
wget -qO- "$hubble_url" | tar xzf - -C "$t" hubble
install "$t/hubble" /usr/local/bin/
rm -rf "$t"
