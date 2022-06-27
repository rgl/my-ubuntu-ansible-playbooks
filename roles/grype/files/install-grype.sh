set -euo pipefail

# bail when already installed.
if [ -x /usr/local/bin/grype ]; then
    # e.g. Version:              0.40.1
    actual_version="$(/usr/local/bin/grype version | perl -ne '/^Version:\s+(.+)$/ && print $1')"
    if [ "$actual_version" == "$GRYPE_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
grype_url="https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz"
t="$(mktemp -q -d --suffix=.grype)"
wget -qO- "$grype_url" | tar xzf - -C "$t" grype
install -m 755 "$t/grype" /usr/local/bin/
rm -rf "$t"
