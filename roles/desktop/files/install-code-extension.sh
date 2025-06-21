#!/bin/bash
set -euxo pipefail

# TODO add support for upgrading the extension to the latest version.

expected="$CODE_EXTENSION_NAME"

# bail when the extension is already installed.
# NB we could also use --show-versions to include the version as @VERSION suffix.
# NB extension ids are case-insensitive.
if code --list-extensions | grep -q -i -F -x "$expected"; then
    echo 'ANSIBLE CHANGED NO'
    exit 0
fi

# install.
code --install-extension "$expected"
