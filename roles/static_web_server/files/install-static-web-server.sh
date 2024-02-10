#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/static-web-server ]; then
    # e.g. static-web-server 2.25.0
    actual_version="$(/usr/local/bin/static-web-server --version | perl -ne '/^static-web-server (.+)/ && print $1')"
    if [ "$actual_version" == "$STATIC_WEB_SERVER_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
static_web_server_url="https://github.com/static-web-server/static-web-server/releases/download/v${STATIC_WEB_SERVER_VERSION}/static-web-server-v${STATIC_WEB_SERVER_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
t="$(mktemp -q -d --suffix=.static-web-server)"
wget -qO- "$static_web_server_url" | tar xzf - -C "$t" --strip-components 1
install -m 755 "$t/static-web-server" /usr/local/bin
rm -rf "$t"
