set -euxo pipefail

ANDROID_STUDIO_PATH='/opt/android-studio'
ANDROID_STUDIO_COOKIE_PATH="$ANDROID_STUDIO_PATH/.ansible-android-studio.cookie"

# bail when already installed.
if [ -f "$ANDROID_STUDIO_COOKIE_PATH" ]; then
    actual_version="$(cat "$ANDROID_STUDIO_COOKIE_PATH")"
    if [ "$actual_version" == "$ANDROID_STUDIO_VERSION" ]; then
        echo 'ANSIBLE CHANGED NO'
        exit 0
    fi
fi

# download and install.
url="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/$ANDROID_STUDIO_VERSION/android-studio-$ANDROID_STUDIO_VERSION-linux.tar.gz"
rm -rf "$ANDROID_STUDIO_PATH"
install -d "$ANDROID_STUDIO_PATH"
wget -qO- "$url" | tar xzf - -C "$ANDROID_STUDIO_PATH" --strip-components 1
echo -n "$ANDROID_STUDIO_VERSION" >"$ANDROID_STUDIO_COOKIE_PATH"
