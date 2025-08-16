#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/terramate ]; then
    # e.g. 0.14.4
    actual_version="$(/usr/local/bin/terramate version)"
    if [ "$actual_version" == "$TERRAMATE_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
# see https://terramate.io/docs/cli/installation
# see https://github.com/terramate-io/terramate/releases
terramate_url="https://github.com/terramate-io/terramate/releases/download/v$TERRAMATE_VERSION/terramate_${TERRAMATE_VERSION}_linux_x86_64.tar.gz"
t="$(mktemp -q -d --suffix=.terramate)"
wget -qO- "$terramate_url" | tar xzf - -C "$t"
install -m 755 "$t/terramate" /usr/local/bin/
install -m 755 "$t/terramate-ls" /usr/local/bin/
rm -rf "$t"
