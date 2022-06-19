set -euo pipefail

# bail when already installed.
if [ -x /opt/go/bin/go ]; then
    # e.g. go version go1.18.1 linux/amd64
    actual_version="$(/opt/go/bin/go version | perl -ne '/^go version go(.+?) / && print $1')"
    if [ "$actual_version" == "$GO_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
rm -rf /opt/go
wget -qO- "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
    | tar xz -C /opt
