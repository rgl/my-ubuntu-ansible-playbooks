set -euo pipefail

# bail when already installed.
if [ -x /usr/local/bin/kind ]; then
    # e.g. kind v0.14.0 go1.18.2 linux/amd64
    actual_version="$(/usr/local/bin/kind version | perl -ne '/^kind v(.+?) / && print $1')"
    if [ "$actual_version" == "$KIND_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
kind_url="https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64"
t="$(mktemp -q --suffix=.kind)"
wget -qO "$t" "$kind_url"
install -m 755 "$t" /usr/local/bin/kind
rm "$t"
