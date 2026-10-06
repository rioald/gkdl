#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
variant=${GKDL_BUILD_VARIANT:-dev}
case "$variant" in
  dev) app_name='gkdl dev'; executable=gkdl-dev; bundle_id=com.zzune.gkdl.dev; archive_prefix=gkdl-dev ;;
  release) app_name=gkdl; executable=gkdl; bundle_id=com.zzune.gkdl; archive_prefix=gkdl ;;
  *) echo 'GKDL_BUILD_VARIANT must be dev or release' >&2; exit 1 ;;
esac
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
output_dir=${GKDL_OUTPUT_DIR:-"$PWD/outputs/$variant"}
stage=$(mktemp -d /private/tmp/gkdl-build.XXXXXX)
app="$stage/$app_name.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$output_dir"
swiftc -parse-as-library -D ICON_GENERATOR -module-cache-path "$stage/module-cache" DudIcon.swift -o "$stage/icon-generator"
"$stage/icon-generator" "$stage/AppIcon.iconset"
iconutil -c icns "$stage/AppIcon.iconset" -o "$app/Contents/Resources/AppIcon.icns"
sources=(main.swift DudIcon.swift KeyboardManagement.swift KeyboardSettings.swift SettingsWindow.swift InputSources.swift UpdateChecking.swift UpdateInstaller.swift SpecialCharacters.swift CorrectionAccessibility.swift TerminalCorrection.swift ManualCorrection.swift KeyboardTests.swift FeatureTests.swift ManualCorrectionTests.swift SelfTest.swift)
compile() { swiftc -swift-version 5 -O -module-cache-path "$stage/module-cache" -import-objc-header Bridge.h "${sources[@]}" -framework AppKit -framework IOKit -framework ServiceManagement "$@"; }
for arch in arm64 x86_64; do
  compile -target "$arch-apple-macos13.0" -o "$stage/gkdl-$arch"
done
lipo -create "$stage/gkdl-arm64" "$stage/gkdl-x86_64" -output "$app/Contents/MacOS/$executable"
cp Info.plist "$app/Contents/Info.plist"
configure_bundle() {
  local path=$1 name=$2 identifier=$3 binary=$4
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $identifier" "$path/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleName $name" "$path/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $name" "$path/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $binary" "$path/Contents/Info.plist"
}
configure_bundle "$app" "$app_name" "$bundle_id" "$executable"
cp LICENSE "$app/Contents/Resources/LICENSE"
cp Resources/github.svg Resources/fairy.svg Resources/OCTICONS-LICENSE "$app/Contents/Resources/"
if [[ -n "${GKDL_APP_VERSION:-}" ]]; then
  [[ "$GKDL_APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 1
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $GKDL_APP_VERSION" "$app/Contents/Info.plist"
fi
if [[ -n "${GKDL_BUILD_NUMBER:-}" ]]; then
  [[ "$GKDL_BUILD_NUMBER" =~ ^[0-9]+$ ]] || exit 1
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $GKDL_BUILD_NUMBER" "$app/Contents/Info.plist"
fi
codesign --force "${sign_args[@]}" --options runtime "$app"
codesign --verify --deep --strict "$app"
# Automated test modes use their own bundle/settings, including during release packaging.
test_app="$stage/test/gkdl dev tests.app"
ditto "$app" "$test_app"
rm "$test_app/Contents/MacOS/$executable"
configure_bundle "$test_app" 'gkdl dev tests' com.zzune.gkdl.dev.tests gkdl-dev-tests
compile -D TESTS -target "$(uname -m)-apple-macos13.0" -o "$test_app/Contents/MacOS/gkdl-dev-tests"
codesign --force "${sign_args[@]}" --options runtime "$test_app"
"$test_app/Contents/MacOS/gkdl-dev-tests" --self-test
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
ditto -c -k --keepParent --norsrc "$app" "$output_dir/$archive_prefix-$version-macos-universal.zip"
codesign -d -r- "$app"
# Expose the local app at a stable path. Always replace the whole generated bundle.
rm -rf "$output_dir/$app_name.app"
ditto "$app" "$output_dir/$app_name.app"
echo "Built app: $output_dir/$app_name.app"
echo "Test app: $test_app"
