#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MODE=${1:-debug}
GODOT_BIN=${GODOT_BIN:-godot}
SDK=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}
JDK=${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}
TEMPLATES=${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.4.1.stable
[[ $("$GODOT_BIN" --version) == 4.4.1.stable* ]] || { echo "Godot 4.4.1 stable is required." >&2; exit 1; }
[[ -x "$SDK/platform-tools/adb" && -x "$SDK/build-tools/34.0.0/apksigner" ]] || { echo 'Run tools/install_android_tools.sh first (SDK 34 required).' >&2; exit 1; }
[[ -f "$TEMPLATES/android_debug.apk" ]] || { echo 'Godot 4.4.1 export templates missing.' >&2; exit 1; }
mkdir -p "$ROOT/build"
touch "$ROOT/build/.gdignore"
case "$MODE" in
  debug) PRESET='Android Debug'; FLAG=--export-debug; OUTPUT="$ROOT/build/binh-doan-ti-hon-debug.apk" ;;
  release)
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Set the release keystore path}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Set the release key alias}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Set the release password}"
    [[ -f "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" ]] || { echo 'Release keystore does not exist.' >&2; exit 1; }
    PRESET='Android Release AAB'; FLAG=--export-release; OUTPUT="$ROOT/build/binh-doan-ti-hon-release.aab"
    if [[ ! -f "$ROOT/build/android/build/gradlew" ]]; then
      mkdir -p "$ROOT/build/android/build"
      unzip -q "$TEMPLATES/android_source.zip" -d "$ROOT/build/android/build"
      printf '%s\n' '4.4.1.stable' > "$ROOT/build/android/.build_version"
      chmod +x "$ROOT/build/android/build/gradlew"
    fi
    ;;
  *) echo 'Usage: tools/build_android.sh [debug|release]' >&2; exit 2 ;;
esac
mkdir -p "$ROOT/build/godot-config/godot"
export XDG_CONFIG_HOME="$ROOT/build/godot-config"
export ANDROID_HOME="$SDK" JAVA_HOME="$JDK"
# A separate editor settings file keeps this build reproducible without changing the user's editor.
python3 - "$SDK" "$JDK" "$XDG_CONFIG_HOME/godot/editor_settings-4.4.tres" <<'PY'
import json, pathlib, sys
sdk,jdk,path=sys.argv[1:]
pathlib.Path(path).write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\nexport/android/android_sdk_path = '+json.dumps(sdk)+'\nexport/android/java_sdk_path = '+json.dumps(jdk)+'\n')
PY
"$GODOT_BIN" --headless --path "$ROOT" --editor --import 2>&1 | tee "$ROOT/build/android-import.log"
if grep -Eq '^(SCRIPT ERROR:|ERROR:)' "$ROOT/build/android-import.log"; then
  echo "Godot import reported errors; resolve them before exporting." >&2; exit 1
fi
"$GODOT_BIN" --headless --path "$ROOT" "$FLAG" "$PRESET" "$OUTPUT"
[[ -s "$OUTPUT" ]]
if [[ "$MODE" == debug ]]; then
  "$SDK/build-tools/34.0.0/apksigner" verify --verbose "$OUTPUT"
  "$SDK/build-tools/34.0.0/aapt" dump badging "$OUTPUT"
else
  "$JDK/bin/jarsigner" -verify "$OUTPUT"
fi
printf 'Built %s\n' "$OUTPUT"
