set -euxo pipefail

# bail when already installed.
if [ -r /opt/umlet/umlet.jar ]; then
    # e.g. Implementation-Version: 15.1
    actual_version="$(unzip -p /opt/umlet/umlet.jar META-INF/MANIFEST.MF | perl -ne '/^\s*Implementation-Version:\s*(.+)/ && print $1 =~ s/[\r\n]+//r')"
    if [ "$actual_version" == "$UMLET_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
umlet_url="https://umlet.com/download/umlet_$(echo $UMLET_VERSION | perl -pe 's/\./_/g')/umlet-standalone-${UMLET_VERSION}.zip"
t="$(mktemp -q -d --suffix=.umlet)"
wget -qO "$t/umlet.zip" "$umlet_url"
unzip "$t/umlet.zip" -d "$t"
rm -rf /opt/umlet
install -d /opt/umlet
find "$t/Umlet" -type d -exec chmod 755 {} \;
find "$t/Umlet" -type f -exec chmod 444 {} \;
mv "$t/Umlet"/* /opt/umlet
rm -rf "$t"
