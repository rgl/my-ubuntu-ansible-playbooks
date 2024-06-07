#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/cmctl ]; then
    # e.g. Client Version: v1.11.2
    actual_version="$(/usr/local/bin/cmctl version --client --short | perl -ne '/^Client Version: v(.+)/ && print $1')"
    if [ "$actual_version" == "$CMCTL_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
cmctl_url="https://github.com/cert-manager/cmctl/releases/download/v${CMCTL_VERSION}/cmctl_linux_amd64"
t="$(mktemp -q -d --suffix=.cmctl)"
wget -qO "$t/cmctl" "$cmctl_url"
install "$t/cmctl" /usr/local/bin/
rm -rf "$t"
