#!/bin/bash
set -euo pipefail

# TODO add support for upgrading the plugin to the latest version.

expected="$CODE_PLUGIN_NAME"

# bail when the extension is already installed.
# NB we could also use --show-versions to include the version as @VERSION suffix.
# NB extension ids are case-insensitive.
code --list-extensions | while read actual; do
    if [ "${actual,,}" == "${expected,,}" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
done

# install.
code --install-extension "$expected"
