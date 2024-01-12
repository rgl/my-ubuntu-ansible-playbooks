set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/javy ]; then
    # e.g. javy 1.3.0
    actual_version="$(/usr/local/bin/javy --version | perl -ne '/^javy (.+)$/ && print $1')"
    if [ "$actual_version" == "$JAVY_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
javy_url="https://github.com/bytecodealliance/javy/releases/download/v${JAVY_VERSION}/javy-x86_64-linux-v${JAVY_VERSION}.gz"
t="$(mktemp -q -d --suffix=.javy)"
wget -qO- "$javy_url" | zcat > "$t/javy"
install -m 755 "$t/javy" /usr/local/bin/
rm -rf "$t"
