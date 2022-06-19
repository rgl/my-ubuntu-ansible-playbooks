set -euo pipefail

# bail when already installed.
if [ -x /usr/local/bin/dagger ]; then
    # e.g. dagger 0.2.6 (e2c2213a) linux/amd64
    actual_version="$(/usr/local/bin/dagger version | perl -ne '/^dagger (.+?) / && print $1')"
    if [ "$actual_version" == "$DAGGER_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
dagger_url="https://github.com/dagger/dagger/releases/download/v${DAGGER_VERSION}/dagger_v${DAGGER_VERSION}_linux_amd64.tar.gz"
t="$(mktemp -q -d --suffix=.dagger)"
wget -qO- "$dagger_url" | tar xzf - -C "$t" dagger
install "$t/dagger" /usr/local/bin/
rm -rf "$t"
