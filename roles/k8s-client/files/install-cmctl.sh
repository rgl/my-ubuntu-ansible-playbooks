set -euo pipefail

# bail when already installed.
if [ -x /usr/local/bin/cmctl ]; then
    # e.g. Client Version: v1.10.0
    actual_version="$(/usr/local/bin/cmctl version --client --short | perl -ne '/^Client Version: v(.+)/ && print $1')"
    if [ "$actual_version" == "$CMCTL_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
cmctl_url="https://github.com/cert-manager/cert-manager/releases/download/v${CMCTL_VERSION}/cmctl-linux-amd64.tar.gz"
t="$(mktemp -q -d --suffix=.cmctl)"
wget -qO- "$cmctl_url" | tar xzf - -C "$t" cmctl
install "$t/cmctl" /usr/local/bin/
rm -rf "$t"
