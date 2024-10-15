#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/deno ]; then
    # e.g. deno 2.0.0 (stable, release, x86_64-unknown-linux-gnu)
    actual_version="$(/usr/local/bin/deno --version | perl -ne '/^deno ([^ +]+)/ && print $1')"
    if [ "$actual_version" == "$DENO_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
deno_url="https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip"
t="$(mktemp -q -d --suffix=.deno)"
wget -qO "$t/deno.zip" "$deno_url"
unzip -j "$t/deno.zip" -d "$t"
install "$t/deno" /usr/local/bin
rm -rf "$t"

# give it a try.
# NB it should automatically create the denox symlink (equivalent to running
#    deno x).
/usr/local/bin/deno --version
