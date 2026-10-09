#!/usr/bin/env bash
set -euo pipefail
# Godot 4.4 toolchain: https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html
SDK=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}
TEMPLATES=${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.4.1.stable
for cmd in curl unzip java keytool python3; do command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }; done
java -version 2>&1 | head -1
CACHE=$(mktemp -d)
trap 'rm -rf "$CACHE"' EXIT
mkdir -p "$SDK/cmdline-tools" "$TEMPLATES"
if [[ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]]; then
  curl -fL --retry 3 https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o "$CACHE/cmdline.zip"
  unzip -q "$CACHE/cmdline.zip" -d "$CACHE/unpacked"
  mv "$CACHE/unpacked/cmdline-tools" "$SDK/cmdline-tools/latest"
fi
# Review Google's licenses before running this installer; this command accepts them.
set +o pipefail
yes | "$SDK/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK" --licenses
set -o pipefail
"$SDK/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK" 'platform-tools' 'build-tools;34.0.0' 'platforms;android-34'
if [[ ! -f "$TEMPLATES/android_source.zip" || ! -f "$TEMPLATES/android_debug.apk" || ! -f "$TEMPLATES/android_release.apk" ]]; then
  curl -fL --retry 3 'https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=export_templates.tpz' -o "$CACHE/templates.tpz"
  unzip -o -j -q "$CACHE/templates.tpz" 'templates/android*' 'templates/version.txt' -d "$TEMPLATES"
fi
# Precompiled APK/AAB templates need no native compilation. Only install NDK/CMake if adding native plugins.
printf 'SDK: %s\nTemplates: %s\n' "$SDK" "$TEMPLATES"
