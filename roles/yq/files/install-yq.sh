set -euo pipefail

# bail when already installed.
if [ -x /usr/local/bin/yq ]; then
    # e.g. yq (https://github.com/mikefarah/yq/) version v4.30.6
    actual_version="$(/usr/local/bin/yq --version | perl -ne '/version v?(.+)$/ && print $1')"
    if [ "$actual_version" == "$YQ_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
yq_url="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
t="$(mktemp -q --suffix=.yq)"
wget -qO "$t" "$yq_url"
install -m 755 "$t" /usr/local/bin/yq
rm "$t"
