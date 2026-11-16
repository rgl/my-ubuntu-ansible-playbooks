#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -r /opt/zed/.version ]; then
    actual_version="$(cat /opt/zed/.version)"
    if [ "$actual_version" == "$ZED_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
# see https://zed.dev/releases/stable
zed_url="https://github.com/zed-industries/zed/releases/download/v${ZED_VERSION}/zed-linux-x86_64.tar.gz"
t="$(mktemp -q -d --suffix=.zed)"
wget -qO- "$zed_url" | tar xzf - --strip-components 1 -C "$t"
rm -rf /opt/zed
install -d /opt/zed
mv "$t/"* /opt/zed
echo -n "${ZED_VERSION}" >/opt/zed/.version
rm -rf "$t"
