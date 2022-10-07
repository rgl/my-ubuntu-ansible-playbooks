set -euo pipefail

# bail when already installed.
if [ -x /opt/pulumi/pulumi ]; then
    # e.g. v3.41.1
    actual_version="$(/opt/pulumi/pulumi version 2>/dev/null | perl -ne '/^v(.+)/ && print $1')"
    if [ "$actual_version" == "$PULUMI_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
rm -rf /opt/pulumi
wget -qO- "https://get.pulumi.com/releases/sdk/pulumi-v${PULUMI_VERSION}-linux-x64.tar.gz" \
    | tar xz -C /opt
