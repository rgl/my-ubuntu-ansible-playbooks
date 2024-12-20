#!/bin/bash
set -euxo pipefail

# see https://github.com/oras-project/oras/releases
version="${ORAS_VERSION:-1.2.2}"

# bail when already installed.
if [ -x "/usr/local/bin/oras" ]; then
  # e.g. Version:        1.2.2
  actual_version="$(/usr/local/bin/oras version | perl -ne '/^Version:\s+(.+)/ && print $1')"
  if [ "$actual_version" == "$version" ]; then
    echo 'ANSIBLE CHANGED NO'
    exit 0
  fi
fi

# download and install.
url="https://github.com/oras-project/oras/releases/download/v${version}/oras_${version}_linux_amd64.tar.gz"
t="$(mktemp -q -d --suffix=.oras)"
wget -qO- "$url" | tar xzf - -C "$t" --strip-components=0 oras
install -m 755 "$t/oras" /usr/local/bin/oras
rm -rf "$t"
