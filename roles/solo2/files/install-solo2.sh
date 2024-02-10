#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/solo2 ]; then
    # e.g. solo2 0.2.2
    actual_version="$(/usr/local/bin/solo2 --version | perl -ne '/^solo2 (.+)/ && print $1')"
    if [ "$actual_version" == "$SOLO2_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
# see https://github.com/solokeys/solo2-cli
solo2_completions_url="https://github.com/solokeys/solo2-cli/releases/download/v${SOLO2_VERSION}/solo2.completions.bash"
solo2_udev_rules_url="https://github.com/solokeys/solo2-cli/releases/download/v${SOLO2_VERSION}/70-solo2.rules"
solo2_url="https://github.com/solokeys/solo2-cli/releases/download/v${SOLO2_VERSION}/solo2-v${SOLO2_VERSION}-x86_64-unknown-linux-gnu"
t="$(mktemp -q -d --suffix=.solo2)"
wget -qO "$t/solo2.completions.bash" "$solo2_completions_url"
wget -qO "$t/70-solo2.rules" "$solo2_udev_rules_url"
wget -qO "$t/solo2" "$solo2_url"
install -m 644 "$t/solo2.completions.bash" /usr/share/bash-completion/completions/solo2
install -m 644 "$t/70-solo2.rules" /etc/udev/rules.d/
udevadm control --reload-rules
udevadm trigger
install -m 755 "$t/solo2" /usr/local/bin/
rm -rf "$t"
