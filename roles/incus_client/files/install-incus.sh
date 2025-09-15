#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/incus ]; then
    # e.g. 6.16
    # NB incus --version only outputs the major and minor version numbers.
    actual_version="$(/usr/local/bin/incus --version | perl -ne '/^([^ +]+)/ && print $1').0"
    if [ "$actual_version" == "$INCUS_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
incus_url="https://github.com/lxc/incus/releases/download/v${INCUS_VERSION}/bin.linux.incus.x86_64"
t="$(mktemp -q -d --suffix=.incus)"
wget -qO "$t/incus" "$incus_url"
install -m 755 "$t/incus" /usr/local/bin
rm -rf "$t"

# give it a try.
/usr/local/bin/incus --version
