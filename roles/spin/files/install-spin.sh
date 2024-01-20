set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/spin ]; then
    # e.g. spin 2.1.0 (f33bb63 2023-12-14)
    actual_version="$(/usr/local/bin/spin --version | perl -ne '/^spin ([^ ]+)/ && print $1')"
    if [ "$actual_version" == "$SPIN_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
spin_url="https://github.com/fermyon/spin/releases/download/v${SPIN_VERSION}/spin-v${SPIN_VERSION}-linux-amd64.tar.gz"
t="$(mktemp -q -d --suffix=.spin)"
wget -qO- "$spin_url" | tar xzf - -C "$t"
install -m 755 "$t/spin" /usr/local/bin/
rm -rf "$t"
