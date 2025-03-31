#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/xq ]; then
    # e.g. xq version 1.3.0 (2024-12-23T20:09:03Z, 86a755578f7bfb82fddc1f712c96db2f0bf36076)
    actual_version="$(/usr/local/bin/xq --version | perl -ne '/v?(\d+(\.\d+)+(-\S+)?)/ && print $1')"
    if [ "$actual_version" == "$XQ_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://github.com/sibprogrammer/xq/releases/download/v${XQ_VERSION}/xq_${XQ_VERSION}_linux_amd64.tar.gz"
t="$(mktemp -q -d --suffix=.xq)"
wget -qO- "$url" | tar xzf - -C "$t" xq
install -m 755 "$t/xq" /usr/local/bin/xq
rm -rf "$t"
