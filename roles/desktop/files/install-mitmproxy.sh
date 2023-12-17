set -euxo pipefail

# bail when already installed.
if [ -r /usr/local/bin/mitmproxy ]; then
    # e.g. Mitmproxy: 10.1.6 binary
    actual_version="$(/usr/local/bin/mitmproxy --version | perl -ne '/^Mitmproxy: (.+?) / && print $1')"
    if [ "$actual_version" == "$MITMPROXY_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
mitmproxy_url="https://downloads.mitmproxy.org/${MITMPROXY_VERSION}/mitmproxy-${MITMPROXY_VERSION}-linux-x86_64.tar.gz"
t="$(mktemp -q -d --suffix=.mitmproxy)"
wget -qO- "$mitmproxy_url" | tar xzf - -C "$t"
install -m 755 -o root -g root "$t/mitmproxy" /usr/local/bin
install -m 755 -o root -g root "$t/mitmdump" /usr/local/bin
install -m 755 -o root -g root "$t/mitmweb" /usr/local/bin
rm -rf "$t"
