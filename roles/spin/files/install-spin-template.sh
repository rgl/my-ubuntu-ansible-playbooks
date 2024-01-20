set -euxo pipefail

# e.g. https://github.com/fermyon/spin-js-sdk/releases/download/v0.6.1/js2wasm.json
SPIN_TEMPLATE_GIT="https://github.com/${SPIN_TEMPLATE_GITHUB}"

# bail when already installed.
# NB its not possible to get the template branch, so we only check the name.
# TODO review this when https://github.com/fermyon/spin/issues/1149 is addressed.
# TODO review this when https://github.com/fermyon/spin/issues/2235 is addressed.
actual_name="$(spin templates list --format json | jq -r '.[].id' | perl -ne '
$n = quotemeta($ENV{SPIN_TEMPLATE_NAME});
$v = quotemeta($ENV{SPIN_TEMPLATE_VERSION});
if (/^($n)$/) {
    print $1;
}
')"
if [ "$actual_name" == "$SPIN_TEMPLATE_NAME" ]; then
    echo 'ANSIBLE CHANGED NO'
    exit 0
fi

# download and install.
# see https://developer.fermyon.com/spin/v2/managing-templates
# see ~/.local/share/spin/templates/
spin templates install \
    --git "$SPIN_TEMPLATE_GIT" \
    --branch "v$SPIN_TEMPLATE_VERSION"
