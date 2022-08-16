#!/bin/bash
set -euo pipefail

# see https://github.com/regclient/regclient/releases
name="$REGCLIENT_NAME"
version="$REGCLIENT_VERSION"

# bail when already installed.
if [ -x "/usr/local/bin/$name" ]; then
  # e.g. v0.4.4
  actual_version="$("/usr/local/bin/$name" version --format '{{.VCSTag}}' | perl -ne '/^v(.+)/ && print $1')"
  if [ "$actual_version" == "$version" ]; then
    echo 'ANSIBLE CHANGED NO'
    exit 0
  fi
fi

# download and install.
url="https://github.com/regclient/regclient/releases/download/v$version/$name-linux-amd64"
t="$(mktemp -q -d --suffix=.regclient)"
wget "-qO$t/$name" "$url"
install -m 755 "$t/$name" "/usr/local/bin/$name"
rm -rf "$t"
