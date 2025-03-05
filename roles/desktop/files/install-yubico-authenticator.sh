#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -r /opt/yubico-authenticator/data/flutter_assets/version.json ]; then
    actual_version="$(jq -r .version /opt/yubico-authenticator/data/flutter_assets/version.json)"
    if [ "$actual_version" == "$YUBICO_AUTHENTICATOR_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://github.com/Yubico/yubioath-flutter/releases/download/${YUBICO_AUTHENTICATOR_VERSION}/yubico-authenticator-${YUBICO_AUTHENTICATOR_VERSION}-linux.tar.gz"
rm -rf /opt/yubico-authenticator
install -d /opt/yubico-authenticator
wget -qO- "$url" | tar xzf - -C /opt/yubico-authenticator --strip-components 1
