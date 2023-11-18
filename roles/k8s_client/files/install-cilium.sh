set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/cilium ]; then
    # e.g. cilium-cli: v0.15.14 compiled with go1.21.3 on linux/amd64
    actual_version="$(/usr/local/bin/cilium version --client | perl -ne '/^cilium-cli: v(.+?) / && print $1')"
    if [ "$actual_version" == "$CILIUM_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
cilium_url="https://github.com/cilium/cilium-cli/releases/download/v${CILIUM_VERSION}/cilium-linux-amd64.tar.gz"
t="$(mktemp -q -d --suffix=.cilium)"
wget -qO- "$cilium_url" | tar xzf - -C "$t" cilium
install "$t/cilium" /usr/local/bin/
rm -rf "$t"
