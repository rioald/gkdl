#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
variant=${GKDL_BUILD_VARIANT:-dev}
case "$variant" in
  dev) app_name='gkdl dev'; executable=gkdl-dev; bundle_id=com.zzune.gkdl.dev; archive_prefix=gkdl-dev ;;
  beta) app_name='하이 Beta'; executable=gkdl-beta; bundle_id=com.zzune.gkdl.beta; archive_prefix=gkdl-beta ;;
  canary|release) app_name=gkdl; executable=gkdl; bundle_id=com.zzune.gkdl; archive_prefix=gkdl ;;
  *) echo 'GKDL_BUILD_VARIANT must be dev, beta, canary or release' >&2; exit 1 ;;
esac
version=${GKDL_APP_VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)}
channel=$(ruby -r ./scripts/release-metadata.rb -e 'puts ReleaseMetadata.new(ARGV.fetch(0)).channel' "$version")
if [[ "$variant" == canary && "$channel" != canary || "$variant" == release && "$channel" == canary ]]; then
  echo '카나리아 버전은 GKDL_BUILD_VARIANT=canary로 빌드해주세요.' >&2; exit 1
fi
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
mkdir -p "$app/Contents/MacOS" "$app/Contents/Helpers" "$app/Contents/Resources" "$output_dir"
swiftc -parse-as-library -D ICON_GENERATOR -module-cache-path "$stage/module-cache" DudIcon.swift -o "$stage/icon-generator"
"$stage/icon-generator" "$stage/AppIcon.iconset"
iconutil -c icns "$stage/AppIcon.iconset" -o "$app/Contents/Resources/AppIcon.icns"
sources=(main.swift DudIcon.swift KeyboardManagement.swift KeyboardSettings.swift SettingsWindow.swift InputSources.swift UpdateChecking.swift UpdateInstaller.swift SpecialCharacters.swift CLI.swift CLIServer.swift UniversalControl.swift CLITests.swift CorrectionAccessibility.swift TerminalCorrection.swift ManualCorrection.swift KeyboardTests.swift FeatureTests.swift ManualCorrectionTests.swift SelfTest.swift)
variant_flags=()
if [[ "$variant" == beta || "$variant" == canary ]]; then
  sources+=(ArasoBetaIntegration.swift)
  variant_flags=(-D ARASO_BETA)
fi
compile() { swiftc -swift-version 5 -O "${variant_flags[@]}" -module-cache-path "$stage/module-cache" -import-objc-header Bridge.h "${sources[@]}" -framework AppKit -framework IOKit -framework ServiceManagement "$@"; }
for arch in arm64 x86_64; do
  compile -target "$arch-apple-macos13.0" -o "$stage/gkdl-$arch"
  swiftc -swift-version 5 -O -parse-as-library -module-cache-path "$stage/module-cache" CLI.swift CLITool.swift -target "$arch-apple-macos13.0" -o "$stage/cli-$arch"
done
lipo -create "$stage/gkdl-arm64" "$stage/gkdl-x86_64" -output "$app/Contents/MacOS/$executable"
lipo -create "$stage/cli-arm64" "$stage/cli-x86_64" -output "$app/Contents/Helpers/gkdl"
cp Info.plist "$app/Contents/Info.plist"
configure_bundle() {
  local path=$1 name=$2 identifier=$3 binary=$4
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $identifier" "$path/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleName $name" "$path/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $name" "$path/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $binary" "$path/Contents/Info.plist"
}
configure_bundle "$app" "$app_name" "$bundle_id" "$executable"
if [[ "$variant" == canary ]]; then
  /usr/libexec/PlistBuddy -c 'Add :GKDLChannel string canary' "$app/Contents/Info.plist"
fi
cp LICENSE "$app/Contents/Resources/LICENSE"
cp Resources/github.svg Resources/fairy.svg Resources/OCTICONS-LICENSE "$app/Contents/Resources/"
if [[ -n "${GKDL_APP_VERSION:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $GKDL_APP_VERSION" "$app/Contents/Info.plist"
fi
if [[ -n "${GKDL_BUILD_NUMBER:-}" ]]; then
  [[ "$GKDL_BUILD_NUMBER" =~ ^[0-9]+$ ]] || exit 1
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $GKDL_BUILD_NUMBER" "$app/Contents/Info.plist"
fi
codesign --force "${sign_args[@]}" --identifier "$bundle_id.cli" --options runtime "$app/Contents/Helpers/gkdl"
if [[ "$variant" == beta || "$variant" == canary ]]; then
  bash scripts/build-araso-beta.sh "$stage" "$app"
  codesign --force "${sign_args[@]}" --options runtime "$app/Contents/PlugIns/HiBetaInput.app"
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
"$app/Contents/Helpers/gkdl" help settings >/dev/null
if "$app/Contents/Helpers/gkdl" set no-such=on 2>/dev/null; then exit 1; else test $? -eq 2; fi
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
ditto -c -k --keepParent --norsrc "$app" "$output_dir/$archive_prefix-$version-macos-universal.zip"
codesign -d -r- "$app"
# Expose the local app at a stable path. Always replace the whole generated bundle.
rm -rf "$output_dir/$app_name.app"
ditto "$app" "$output_dir/$app_name.app"
echo "Built app: $output_dir/$app_name.app"
echo "Test app: $test_app"
