#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/wasmtime ]; then
    # e.g. wasmtime-cli 16.0.0 (6613acd1e 2023-12-20)
    actual_version="$(/usr/local/bin/wasmtime --version | perl -ne '/^wasmtime-cli ([^ ]+)/ && print $1')"
    if [ "$actual_version" == "$WASMTIME_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
wasmtime_url="https://github.com/bytecodealliance/wasmtime/releases/download/v${WASMTIME_VERSION}/wasmtime-v${WASMTIME_VERSION}-x86_64-linux.tar.xz"
t="$(mktemp -q -d --suffix=.wasmtime)"
wget -qO- "$wasmtime_url" | tar xJ -C "$t" --strip-components 1
install -m 755 "$t/wasmtime" /usr/local/bin/
rm -rf "$t"
