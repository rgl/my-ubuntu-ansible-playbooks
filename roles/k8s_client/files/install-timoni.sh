set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/timoni ]; then
    # e.g. timoni version 0.17.0
    actual_version="$(/usr/local/bin/timoni --version | perl -ne '/^timoni version (.+)/ && print $1')"
    if [ "$actual_version" == "$TIMONI_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
timoni_url="https://github.com/stefanprodan/timoni/releases/download/v${TIMONI_VERSION}/timoni_${TIMONI_VERSION}_linux_amd64.tar.gz"
t="$(mktemp -q -d --suffix=.timoni)"
wget -qO- "$timoni_url" | tar xzf - -C "$t" timoni
install "$t/timoni" /usr/local/bin/
rm -rf "$t"
