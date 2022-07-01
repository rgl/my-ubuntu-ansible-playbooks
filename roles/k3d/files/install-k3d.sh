set -euo pipefail

# bail when already installed.
if [ -x /usr/local/bin/k3d ]; then
    # e.g. k3d version v5.4.3
    actual_version="$(/usr/local/bin/k3d version | perl -ne '/^k3d version v(.+?)$/ && print $1')"
    if [ "$actual_version" == "$K3D_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
k3d_url="https://github.com/k3d-io/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64"
t="$(mktemp -q --suffix=.k3d)"
wget -qO "$t" "$k3d_url"
install -m 755 "$t" /usr/local/bin/k3d
rm "$t"
