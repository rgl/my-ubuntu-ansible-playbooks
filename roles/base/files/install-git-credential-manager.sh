#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/git-credential-manager ]; then
    # e.g. 2.4.1
    actual_version="$(/usr/local/bin/git-credential-manager --version)"
    if [ "$actual_version" == "$GIT_CREDENTIAL_MANAGER_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
gcm_url="https://github.com/git-ecosystem/git-credential-manager/releases/download/v${GIT_CREDENTIAL_MANAGER_VERSION}/gcm-linux_amd64.${GIT_CREDENTIAL_MANAGER_VERSION}.deb"
t="$(mktemp -q -d --suffix=.gcm)"
wget -qO "$t/gcm.deb" "$gcm_url"
dpkg -i "$t/gcm.deb"
rm -rf "$t"

# give it a try.
/usr/local/bin/git-credential-manager --version
