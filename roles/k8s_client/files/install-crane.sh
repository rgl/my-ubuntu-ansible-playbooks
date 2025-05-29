#!/bin/bash
set -euxo pipefail

# see https://github.com/google/go-containerregistry/releases
version="${CRANE_VERSION:-0.20.5}"

# bail when already installed.
if [ -x "/usr/local/bin/crane" ]; then
  # e.g. 0.20.5
  actual_version="$(/usr/local/bin/crane version)"
  if [ "$actual_version" == "$version" ]; then
    echo 'ANSIBLE CHANGED NO'
    exit 0
  fi
fi

# download and install.
url="https://github.com/google/go-containerregistry/releases/download/v$version/go-containerregistry_Linux_x86_64.tar.gz"
t="$(mktemp -q -d --suffix=.crane)"
wget -qO- "$url" | tar xzf - -C "$t" --strip-components=0 crane
install -m 755 "$t/crane" /usr/local/bin/crane
rm -rf "$t"
