set -euxo pipefail

# bail when already installed.
if [ -x /opt/tinygo/bin/tinygo ]; then
    # e.g. tinygo version 0.30.0 linux/amd64 (using go version go1.21.6 and LLVM version 16.0.1)
    actual_version="$(/opt/tinygo/bin/tinygo version | perl -ne '/^tinygo version (.+?) / && print $1')"
    if [ "$actual_version" == "$TINYGO_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
rm -rf /opt/tinygo
wget -qO- "https://github.com/tinygo-org/tinygo/releases/download/v${TINYGO_VERSION}/tinygo${TINYGO_VERSION}.linux-amd64.tar.gz" \
    | tar xz -C /opt
