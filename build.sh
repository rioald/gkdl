#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mode=${GKDL_SIGN_MODE:-ad-hoc}
sign_args=()
case "$mode" in
  developer-id)
    : "${GKDL_SIGN_IDENTITY:?Set Developer ID Application signing identity}"
    sign_args=(--sign "$GKDL_SIGN_IDENTITY" --timestamp)
    ;;
  ad-hoc)
    echo 'WARNING: ad-hoc signing does not preserve app identity across updates.' >&2
    sign_args=(--sign - --timestamp=none)
    ;;
  *) echo 'GKDL_SIGN_MODE must be developer-id or ad-hoc' >&2; exit 1 ;;
esac
output_dir=${GKDL_OUTPUT_DIR:-"$PWD/outputs"}
stage=$(mktemp -d /private/tmp/gkdl-build.XXXXXX)
mkdir -p "$stage/gkdl.app/Contents/MacOS" "$stage/gkdl.app/Contents/Resources" "$output_dir"
swiftc -parse-as-library -D ICON_GENERATOR -module-cache-path "$stage/module-cache" GkdlIcon.swift -o "$stage/icon-generator"
"$stage/icon-generator" "$stage/AppIcon.iconset"
iconutil -c icns "$stage/AppIcon.iconset" -o "$stage/gkdl.app/Contents/Resources/AppIcon.icns"
sources=(main.swift GkdlIcon.swift KeyboardManagement.swift KeyboardSettings.swift SettingsWindow.swift InputSources.swift UpdateChecking.swift UpdateInstaller.swift SpecialCharacters.swift CorrectionText.swift CorrectionAccessibility.swift TerminalCorrection.swift ManualCorrection.swift KeyboardTests.swift FeatureTests.swift ManualCorrectionTests.swift SelfTest.swift)
compile() { swiftc -swift-version 5 -O -module-cache-path "$stage/module-cache" -import-objc-header Bridge.h "${sources[@]}" -framework AppKit -framework IOKit -framework ServiceManagement "$@"; }
for arch in arm64 x86_64; do
  compile -target "$arch-apple-macos13.0" -o "$stage/gkdl-$arch"
done
lipo -create "$stage/gkdl-arm64" "$stage/gkdl-x86_64" -output "$stage/gkdl.app/Contents/MacOS/gkdl"
cp Info.plist "$stage/gkdl.app/Contents/Info.plist"
cp LICENSE NOTICE "$stage/gkdl.app/Contents/Resources/"
cp Resources/github.svg Resources/OCTICONS-LICENSE "$stage/gkdl.app/Contents/Resources/"
if [[ -n "${GKDL_APP_VERSION:-}" ]]; then
  [[ "$GKDL_APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 1
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $GKDL_APP_VERSION" "$stage/gkdl.app/Contents/Info.plist"
fi
if [[ -n "${GKDL_BUILD_NUMBER:-}" ]]; then
  [[ "$GKDL_BUILD_NUMBER" =~ ^[0-9]+$ ]] || exit 1
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $GKDL_BUILD_NUMBER" "$stage/gkdl.app/Contents/Info.plist"
fi
codesign --force "${sign_args[@]}" --options runtime "$stage/gkdl.app"
codesign --verify --deep --strict "$stage/gkdl.app"
# The release app has no test code; the same bundle with the test modes compiled in (-D TESTS) runs them.
test_app="$stage/test/gkdl.app"
ditto "$stage/gkdl.app" "$test_app"
compile -D TESTS -target "$(uname -m)-apple-macos13.0" -o "$test_app/Contents/MacOS/gkdl"
codesign --force "${sign_args[@]}" --options runtime "$test_app"
"$test_app/Contents/MacOS/gkdl" --self-test
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$stage/gkdl.app/Contents/Info.plist")
ditto -c -k --keepParent --norsrc "$stage/gkdl.app" "$output_dir/gkdl-$version-macos-universal.zip"
codesign -d -r- "$stage/gkdl.app"
echo "Built app: $stage/gkdl.app"
echo "Test app: $test_app"
