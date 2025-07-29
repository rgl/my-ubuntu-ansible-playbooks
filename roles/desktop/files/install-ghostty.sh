#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/bin/ghostty ]; then
    # e.g. Ghostty 1.1.3
    actual_version="$(/usr/bin/ghostty --version | perl -ne '/^Ghostty (.+)/ && print $1')"
    if [ "$actual_version" == "$GHOSTTY_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
u="https://github.com/mkasberg/ghostty-ubuntu/releases/download/${GHOSTTY_VERSION}-0-ppa2/ghostty_${GHOSTTY_VERSION}-0.ppa2_amd64_$(lsb_release -s -r).deb"
t="$(mktemp -q -d --suffix=.ghostty)"
wget -qO "$t/ghostty.deb" "$u"
dpkg -i "$t/ghostty.deb"
rm -rf "$t"

# give it a try.
/usr/bin/ghostty --version
