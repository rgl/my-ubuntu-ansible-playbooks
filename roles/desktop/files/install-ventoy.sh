set -euo pipefail

# bail when already installed.
if [ -r /opt/ventoy/ventoy/version ]; then
    # e.g. 1.0.91
    actual_version="$(cat /opt/ventoy/ventoy/version)"
    if [ "$actual_version" == "$VENTOY_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
ventoy_url="https://github.com/ventoy/Ventoy/releases/download/v${VENTOY_VERSION}/ventoy-${VENTOY_VERSION}-linux.tar.gz"
rm -rf /opt/ventoy
install -d /opt/ventoy
wget -qO- "$ventoy_url" | tar xzf - -C /opt/ventoy --strip-components 2
