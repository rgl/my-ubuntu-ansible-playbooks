set -euxo pipefail

cargo_bin="$HOME/.cargo/bin"
rustc="$cargo_bin/rustc"
rustup="$cargo_bin/rustup"
changed='0'

# install rust.
# see https://www.rust-lang.org/tools/install
# see https://github.com/clux/muslrust/blob/main/Dockerfile
# e.g. rustc 1.64.0 (a55dd71d5 2022-09-19)
actual_version="$("$rustc" --version 2>/dev/null | perl -ne '/^rustc (.+?) / && print $1' || true)"
if [ "$actual_version" != "$RUST_VERSION" ]; then
    rm -rf ~/.{cargo,rustup}
    u='https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init'
    t="$(mktemp -q -d --suffix=.rustup-init)"
    wget -qO "$t/rustup-init" "$u"
    chmod +x "$t/rustup-init"
    "$t/rustup-init" --no-update-default-toolchain -y
    rm -rf "$t"
    "$rustup" default "$RUST_VERSION"
    changed='1'
fi

# install the wasm32-wasi target.
if [ -z "$("$rustup" target list --installed | grep -E '^wasm32-wasi$')" ]; then
    "$rustup" target add wasm32-wasi
    changed='1'
fi

if [ "$changed" == '0' ]; then
    echo 'ANSIBLE CHANGED NO'
fi
