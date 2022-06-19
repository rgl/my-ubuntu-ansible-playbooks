set -euo pipefail

# bail when already installed.
if [ -x /usr/local/bin/cue ]; then
    # e.g. cue version v0.4.1 linux/amd64
    actual_version="$(/usr/local/bin/cue version | perl -ne '/^cue version v(.+?) / && print $1')"
    if [ "$actual_version" == "$CUE_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
cue_url="https://github.com/cue-lang/cue/releases/download/v${CUE_VERSION}/cue_v${CUE_VERSION}_linux_amd64.tar.gz"
t="$(mktemp -q -d --suffix=.cue)"
wget -qO- "$cue_url" | tar xzf - -C "$t" cue
install "$t/cue" /usr/local/bin/
rm -rf "$t"
