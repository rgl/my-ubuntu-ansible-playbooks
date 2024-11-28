#!/bin/bash
set -euxo pipefail

ANDROID_SDK_PATH='/opt/android-sdk'
ANDROID_SDK_COOKIE_PATH="$ANDROID_SDK_PATH/.ansible-android-sdk.cookie"

# install cmdline-tools.
# see https://developer.android.com/tools#tools-sdk
# NB the Android SDK Command-Line Tools replace the deprecated SDK Tools.
install='1'
if [ -f "$ANDROID_SDK_COOKIE_PATH" ]; then
    actual_version="$(cat "$ANDROID_SDK_COOKIE_PATH")"
    if [ "$actual_version" == "$ANDROID_SDK_CMDLINE_TOOLS_BUILD" ]; then
        install='0'
    fi
fi
if [ "$install" == '1' ]; then
    url="https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_CMDLINE_TOOLS_BUILD}_latest.zip"
    t="$(mktemp -q -d --suffix=.android-sdk)"
    wget -qO "$t/cmdline-tools.zip" "$url"
    unzip -q "$t/cmdline-tools.zip" -d "$t"
    rm -rf "$ANDROID_SDK_PATH"
    (yes || true) | "$t/cmdline-tools/bin/sdkmanager" \
        --sdk_root="$ANDROID_SDK_PATH" \
        --licenses
    "$t/cmdline-tools/bin/sdkmanager" \
        --sdk_root="$ANDROID_SDK_PATH" \
        --install "cmdline-tools;$ANDROID_SDK_CMDLINE_TOOLS_VERSION"
    rm -rf "$t"
    echo -n "$ANDROID_SDK_CMDLINE_TOOLS_BUILD" >"$ANDROID_SDK_COOKIE_PATH"
    echo 'ANSIBLE CHANGED YES'
fi

# install packages.
perl -n -e '/^\s*(.+?)\s*$/ && print "$1\n"' <<< "$ANDROID_SDK_PACKAGES" | while IFS= read -r package; do
    "$ANDROID_SDK_PATH/cmdline-tools/$ANDROID_SDK_CMDLINE_TOOLS_VERSION/bin/sdkmanager" \
        --sdk_root="$ANDROID_SDK_PATH" \
        --install "$package"
done
