#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/uv ]; then
    # e.g.: uv 0.8.15
    actual_version="$(/usr/local/bin/uv --version | perl -ne '/^uv (.+)/ && print $1')"
    if [ "$actual_version" == "$UV_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-x86_64-unknown-linux-gnu.tar.gz"
t="$(mktemp -q -d --suffix=.uv)"
pushd "$t"
wget -qO- "$url" | tar xzf - --strip-components 1
install -m 755 uv uvx /usr/local/bin
popd
rm -rf "$t"
