set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/bun ]; then
    # e.g. 1.0.0
    actual_version="$(/usr/local/bin/bun --version)"
    if [ "$actual_version" == "$BUN_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
bun_url="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip"
t="$(mktemp -q -d --suffix=.bun)"
wget -qO "$t/bun.zip" "$bun_url"
unzip -j "$t/bun.zip" -d "$t"
install "$t/bun" /usr/local/bin
rm -rf "$t"

# give it a try.
# NB it should automatically create the bunx symlink (equivalent to running
#    bun x).
/usr/local/bin/bun --version
