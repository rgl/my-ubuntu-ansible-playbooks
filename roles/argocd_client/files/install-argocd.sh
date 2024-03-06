#!/bin/bash
set -euxo pipefail

# bail when already installed.
if [ -x /usr/local/bin/argocd ]; then
    # e.g. argocd: v2.10.2+fcf5d8c
    actual_version="$(/usr/local/bin/argocd version --client | perl -ne '/^argocd: v([^ +]+)/ && print $1')"
    if [ "$actual_version" == "$ARGOCD_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
# see https://argo-cd.readthedocs.io/en/stable/cli_installation/
# see https://github.com/argoproj/argo-cd/releases
argocd_url="https://github.com/argoproj/argo-cd/releases/download/v$ARGOCD_VERSION/argocd-linux-amd64"
t="$(mktemp -q -d --suffix=.argocd)"
wget -qO "$t/argocd" "$argocd_url"
install -m 755 "$t/argocd" /usr/local/bin/
rm -rf "$t"
