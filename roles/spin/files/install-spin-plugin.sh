set -euxo pipefail

# e.g. https://github.com/fermyon/spin-js-sdk/releases/download/v0.6.1/js2wasm.json
SPIN_PLUGIN_URL="https://github.com/${SPIN_PLUGIN_GITHUB}/releases/download/v${SPIN_PLUGIN_VERSION}/${SPIN_PLUGIN_NAME}.json"

# bail when already installed.
actual_version="$(spin plugins list --installed | perl -ne '
$n = quotemeta($ENV{SPIN_PLUGIN_NAME});
$v = quotemeta($ENV{SPIN_PLUGIN_VERSION});
# e.g. js2wasm 0.6.1 [installed]
if (/^$n\s+($v)\s+/) {
    print $1;
}
')"
if [ "$actual_version" == "$SPIN_PLUGIN_VERSION" ]; then
    echo 'ANSIBLE CHANGED NO'
    exit 0
fi

# download and install.
# see https://developer.fermyon.com/spin/v2/managing-plugins
# see ~/.local/share/spin/plugins/
spin plugins install --yes --url "$SPIN_PLUGIN_URL"
