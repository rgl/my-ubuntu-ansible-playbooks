set -euo pipefail

wasmer="$HOME/.wasmer/bin/wasmer"
changed='0'

# install wasmer.
# see https://github.com/wasmerio/wasmer-install
# see https://github.com/wasmerio/wasmer-install/blob/master/install.sh
# e.g. wasmer 3.0.1
actual_version="$("$wasmer" --version 2>/dev/null | perl -ne '/^wasmer (.+)$/ && print $1' || true)"
if [ "$actual_version" != "$WASMER_VERSION" ]; then
    rm -rf ~/.wasmer
    wget -qO- https://get.wasmer.io \
        | sh -s "v$WASMER_VERSION"
    changed='1'
fi

if [ "$changed" == '0' ]; then
    echo 'ANSIBLE CHANGED NO'
fi
