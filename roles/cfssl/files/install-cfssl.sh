set -euo pipefail

changed='false'

for name in cfssl cfssljson; do
    # bail when already installed.
    if [ -x /usr/local/bin/$name ]; then
        # e.g. Version: 1.6.1
        if [ "$name" == 'cfssl' ]; then
            actual_version="$(/usr/local/bin/$name version | perl -ne '/^Version: (.+)$/ && print $1')"
        else
            actual_version="$(/usr/local/bin/$name -version | perl -ne '/^Version: (.+)$/ && print $1')"
        fi
        if [ "$actual_version" == "$CFSSL_VERSION" ]; then
            continue
        fi
    fi
    changed='true'

    # download and install.
    cfssl_url="https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VERSION}/${name}_${CFSSL_VERSION}_linux_amd64"
    t="$(mktemp -q --suffix=.$name)"
    wget -qO "$t" "$cfssl_url"
    install -m 755 "$t" "/usr/local/bin/$name"
    rm "$t"
done

if [ "$changed" == 'false' ]; then
    echo 'ANSIBLE CHANGED NO'
fi
