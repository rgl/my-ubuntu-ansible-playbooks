#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/talosctl ]; then
    # e.g. Talos v1.10.5
    actual_version="$(/usr/local/bin/talosctl version --client --short | perl -ne '/^Talos v(.+)/ && print $1')"
    if [ "$actual_version" == "$TALOSCTL_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
talosctl_url="https://github.com/siderolabs/talos/releases/download/v${TALOSCTL_VERSION}/talosctl-linux-amd64"
t="$(mktemp -q --suffix=.talosctl)"
wget -q -O "$t" "$talosctl_url"
install -m 755 "$t" /usr/local/bin/talosctl
rm "$t"
