#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /opt/zig/zig ]; then
    # e.g. 0.13.1
    actual_version="$(/opt/zig/zig version | perl -ne '/^(.+)/ && print $1')"
    if [ "$actual_version" == "$ZIG_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
# see https://ziglang.org/download/
rm -rf /opt/zig
install -d /opt/zig
wget -qO- https://ziglang.org/download/$ZIG_VERSION/zig-x86_64-linux-$ZIG_VERSION.tar.xz \
    | tar xJ -C /opt/zig --strip-components 1
