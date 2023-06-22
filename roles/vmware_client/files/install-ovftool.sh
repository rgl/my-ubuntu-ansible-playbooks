set -euxo pipefail

# transform version from <major>.<minor>.<patch>.<build> to <major>.<minor>.<patch>-<build>.
OVFTOOL_VERSION="$(echo "$OVFTOOL_VERSION" | perl -ne '/^(.+)\.(.+?)$/ && print "$1-$2"')"

# bail when already installed.
if [ -f /usr/local/bin/ovftool ]; then
    # e.g. VMware ovftool 4.5.0 (build-20459872)
    actual_version="$(/usr/local/bin/ovftool --version | perl -ne '/^VMware ovftool (.+) \(build(-.+)\)/ && print "$1$2"')"
    if [ "$actual_version" == "$OVFTOOL_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download.
url="https://github.com/rgl/ovftool-binaries/raw/main/archive/VMware-ovftool-$OVFTOOL_VERSION-lin.x86_64.zip"
rm -f /tmp/ovftool.zip
wget -q -O /tmp/ovftool.zip $url

# install.
rm -rf /opt/ovftool
unzip -q -d /opt /tmp/ovftool.zip
rm /tmp/ovftool.zip
ln -fs /etc/ssl/certs/ca-certificates.crt /opt/ovftool/certs/cacert.pem
ln -fs /opt/ovftool/ovftool /usr/local/bin/
