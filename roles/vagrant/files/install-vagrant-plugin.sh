#!/bin/bash
set -euo pipefail

# e.g. vagrant-windows-sysprep (0.0.10, global)
actual_version="$(vagrant plugin list | perl -ne '
$n = quotemeta($ENV{VAGRANT_PLUGIN_NAME});
$v = quotemeta($ENV{VAGRANT_PLUGIN_VERSION});
if (/^$n \((.+)\)/) {
    @versions = split(/\s*,\s*/, $1);
    if (grep(/^$v$/, @versions)) {
        print $ENV{VAGRANT_PLUGIN_VERSION};
    }
}
')"

if [ "$actual_version" == "$VAGRANT_PLUGIN_VERSION" ]; then
    echo 'ANSIBLE CHANGED NO'
    exit 0
fi

vagrant plugin install \
    --no-tty \
    --plugin-version "$VAGRANT_PLUGIN_VERSION" \
    "$VAGRANT_PLUGIN_NAME"
