set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/wasm-tools ]; then
    # e.g. wasm-tools 1.0.56 (a6160b386 2024-01-24)
    actual_version="$(/usr/local/bin/wasm-tools --version | perl -ne '/^wasm-tools ([^ ]+)/ && print $1')"
    if [ "$actual_version" == "$WASM_TOOLS_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
wasm_tools_url="https://github.com/bytecodealliance/wasm-tools/releases/download/wasm-tools-${WASM_TOOLS_VERSION}/wasm-tools-${WASM_TOOLS_VERSION}-x86_64-linux.tar.gz"
t="$(mktemp -q -d --suffix=.wasm-tools)"
wget -qO- "$wasm_tools_url" | tar xzf - -C "$t" --strip-components 1
install -m 755 "$t/wasm-tools" /usr/local/bin/
rm -rf "$t"
