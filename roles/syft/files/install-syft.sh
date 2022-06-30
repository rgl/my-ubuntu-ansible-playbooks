set -euo pipefail

# bail when already installed.
if [ -x /usr/local/bin/syft ]; then
    # e.g. syft 0.49.0
    actual_version="$(/usr/local/bin/syft --version | perl -ne '/^syft (.+)$/ && print $1')"
    if [ "$actual_version" == "$SYFT_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
syft_url="https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz"
t="$(mktemp -q -d --suffix=.syft)"
wget -qO- "$syft_url" | tar xzf - -C "$t" syft
install -m 755 "$t/syft" /usr/local/bin/
rm -rf "$t"
