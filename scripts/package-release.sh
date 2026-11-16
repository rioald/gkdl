#!/bin/bash
# 로컬 키체인의 Developer ID로 빌드한다. 설치하거나 공개하지 않는다.
# DMG packaging adapted from gksdud and modified for gkdl; see LICENSE (Apache-2.0).
set -euo pipefail
cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
사용법:
  bash scripts/package-release.sh --signed-only
  GKDL_NOTARY_PROFILE=프로필이름 bash scripts/package-release.sh --notarize

--signed-only: Developer ID 서명만 수행한다. Apple 공증 완료본이 아니다.
--notarize:    서명, Apple 공증, 티켓 첨부, Gatekeeper 검증을 수행한다.

선택 환경변수:
  GKDL_SIGN_IDENTITY  같은 팀의 여러 Developer ID 인증서 중 사용할 SHA-1 지문
  GKDL_PACKAGE_DIR   새 결과 폴더 경로 (기존 폴더는 덮어쓰지 않음)
  GKDL_APP_VERSION / GKDL_BUILD_NUMBER  build.sh의 버전 재정의
EOF
}
[[ $# == 1 ]] || { usage >&2; exit 1; }
case "$1" in
  --help|-h) usage; exit 0 ;;
  --signed-only) status=signed-only ;;
  --notarize) status=notarized ;;
  *) usage >&2; exit 1 ;;
esac

team=KTC97BHY7R
identities=$(security find-identity -v -p codesigning | awk '/"Developer ID Application: TWENTYOZ \(KTC97BHY7R\)"/ { print $2 }')
identity=${GKDL_SIGN_IDENTITY:-}
if [[ -n "$identity" ]]; then
  identity=$(printf '%s' "$identity" | tr '[:lower:]' '[:upper:]')
  [[ "$identity" =~ ^[A-F0-9]{40}$ ]] || { echo '인증서는 40자리 SHA-1 지문으로 지정해주세요.' >&2; exit 1; }
  [[ $'\n'"$identities"$'\n' == *$'\n'"$identity"$'\n'* ]] || {
    echo '지정한 인증서가 배포 팀의 유효한 Developer ID 서명 ID가 아닙니다.' >&2; exit 1;
  }
else
  [[ "$identities" =~ ^[A-F0-9]{40}$ ]] || {
    echo '배포 팀의 Developer ID가 없거나 여러 개입니다. GKDL_SIGN_IDENTITY를 확인해주세요.' >&2; exit 1;
  }
  identity=$identities
fi

version=${GKDL_APP_VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)}
channel=$(ruby -r ./scripts/release-metadata.rb -e 'puts ReleaseMetadata.new(ARGV.fetch(0)).channel' "$version")
variant=release
if [[ "$channel" == canary ]]; then variant=canary; fi
destination=${GKDL_PACKAGE_DIR:-"$PWD/outputs/packages/$version-$status"}
[[ ! -e "$destination" && ! -L "$destination" ]] || { echo "결과 폴더가 이미 있습니다: $destination" >&2; exit 1; }
if [[ "$status" == notarized ]]; then
  [[ -z "$(git status --porcelain)" ]] || { echo '공증 배포 전에 변경사항을 커밋해주세요.' >&2; exit 1; }
  : "${GKDL_NOTARY_PROFILE:?공증에 사용할 notarytool 키체인 프로필 이름을 지정해주세요.}"
  # 빌드 전에 인증을 확인한다. 비밀번호/API 키는 스크립트에서 읽거나 출력하지 않는다.
  xcrun notarytool history --keychain-profile "$GKDL_NOTARY_PROFILE" --output-format json >/dev/null
fi

mkdir -p "$(dirname "$destination")"
stage=$(mktemp -d "$(dirname "$destination")/.gkdl-package.XXXXXX")
trap 'echo "패키징 미완료. 진단 파일: $stage" >&2' ERR
GKDL_BUILD_VARIANT="$variant" GKDL_SIGN_MODE=developer-id GKDL_SIGN_IDENTITY="$identity" GKDL_OUTPUT_DIR="$stage/build" bash build.sh
ditto -x -k "$stage/build/gkdl-$version-macos-universal.zip" "$stage"
app="$stage/gkdl.app"
requirement="=identifier \"com.zzune.gkdl\" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists and certificate leaf[field.1.2.840.113635.100.6.1.13] exists and certificate leaf[subject.OU] = \"$team\""
codesign --verify --deep --strict --all-architectures -R "$requirement" "$app"
for arch in arm64 x86_64; do
  lipo "$app/Contents/MacOS/gkdl" -verify_arch "$arch"
done

if [[ "$status" == notarized ]]; then
  # 접수 ID를 먼저 저장해 timeout/중단 시 같은 제출을 조회할 수 있게 한다.
  xcrun notarytool submit "$stage/build/gkdl-$version-macos-universal.zip" \
    --keychain-profile "$GKDL_NOTARY_PROFILE" --no-wait --output-format json > "$stage/notary-submission.json"
  submission=$(/usr/bin/plutil -extract id raw -o - "$stage/notary-submission.json")
  echo "Apple 공증 접수: $submission"
  wait_status=0
  xcrun notarytool wait "$submission" --keychain-profile "$GKDL_NOTARY_PROFILE" \
    --timeout 20m --output-format json > "$stage/notary-result.json" || wait_status=$?
  result=$(/usr/bin/plutil -extract status raw -o - "$stage/notary-result.json" 2>/dev/null || true)
  if [[ "$result" == Accepted || "$result" == Invalid || "$result" == Rejected ]]; then
    xcrun notarytool log "$submission" --keychain-profile "$GKDL_NOTARY_PROFILE" "$stage/notary-log.json"
  fi
  [[ "$wait_status" == 0 && "$result" == Accepted ]] || {
    echo "Apple 공증 미완료: ${result:-조회 실패}. 접수 ID: $submission, 진단 폴더: $stage" >&2; exit 1;
  }
  if [[ "$variant" == canary ]]; then
    helper="$app/Contents/PlugIns/HiBetaInput.app"
    xcrun stapler staple "$helper"
    xcrun stapler validate "$helper"
    spctl --assess --type execute --verbose=2 "$helper"
  fi
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
  codesign --verify --deep --strict --all-architectures -R "$requirement" "$app"
  spctl --assess --type execute --verbose=2 "$app"
fi

# 공증 티켓이 첨부된 앱을 다시 압축해야 오프라인에서도 티켓을 사용할 수 있다.
archive="gkdl-$version-macos-universal.zip"
ditto -c -k --keepParent --norsrc "$app" "$stage/$archive"

# Use the upstream Finder layout with gkdl's icon and the same stapled app as the ZIP.
swiftc -module-cache-path "$stage/module-cache" DiskImage.swift -o "$stage/disk-image"
mkdir "$stage/dmg"
ditto "$app" "$stage/dmg/gkdl.app"
ln -s /Applications "$stage/dmg/Applications"
"$stage/disk-image" background "$stage/dmg/.background.tiff"
cp "$app/Contents/Resources/AppIcon.icns" "$stage/dmg/.VolumeIcon.icns"
chflags hidden "$stage/dmg/.background.tiff" "$stage/dmg/.VolumeIcon.icns"
size=$(( $(du -sk "$stage/dmg" | cut -f1) * 12 / 10240 + 16 ))m
image="$stage/layout.dmg"
disks() {
  hdiutil info | awk -v image="$image" '/^image-path/ { sub(/^image-path *: /, ""); current = ($0 == image) }
    current && /^\/dev\/disk[0-9]+[ \t]/ { print $1 }'
}
unmount() { local disk; for disk in $(disks); do hdiutil detach -quiet -force "$disk" || true; done; }
detach() { local disk; for disk in $(disks); do hdiutil detach -quiet "$disk" || return 1; done; }
retry() {
  local attempt
  for attempt in 1 2 3 4 5; do
    if "$@"; then return 0; fi
    [[ -z ${retry_cleanup:-} ]] || "$retry_cleanup"
    if [[ $attempt -lt 5 ]]; then sleep $((attempt * 3)); fi
  done
  return 1
}
layout_image() {
  hdiutil create -quiet -ov -volname gkdl -srcfolder "$stage/dmg" -fs HFS+ -format UDRW -size "$size" "$image" &&
    hdiutil attach -quiet -nobrowse -noautoopen -mountpoint "$stage/volume" "$image"
}
trap unmount EXIT
retry_cleanup=unmount retry layout_image
"$stage/disk-image" layout "$stage/volume"
codesign --verify --deep --strict --all-architectures -R "$requirement" "$stage/volume/gkdl.app"
rm -rf "$stage/volume/.fseventsd"
retry detach || unmount
if [[ -n $(disks) ]]; then echo "Cannot detach $image" >&2; exit 1; fi
retry_cleanup=unmount retry hdiutil convert -quiet -ov "$image" -format UDZO -o "$stage/gkdl-$version.dmg"
trap - EXIT
dmg="gkdl-$version.dmg"
codesign --force --sign "$identity" --timestamp --identifier com.zzune.gkdl.dmg "$stage/$dmg"
codesign --verify --strict "$stage/$dmg"
if [[ "$status" == notarized ]]; then
  xcrun notarytool submit "$stage/$dmg" --keychain-profile "$GKDL_NOTARY_PROFILE" \
    --no-wait --output-format json > "$stage/dmg-notary-submission.json"
  submission=$(/usr/bin/plutil -extract id raw -o - "$stage/dmg-notary-submission.json")
  echo "Apple DMG 공증 접수: $submission"
  wait_status=0
  xcrun notarytool wait "$submission" --keychain-profile "$GKDL_NOTARY_PROFILE" \
    --timeout 20m --output-format json > "$stage/dmg-notary-result.json" || wait_status=$?
  result=$(/usr/bin/plutil -extract status raw -o - "$stage/dmg-notary-result.json" 2>/dev/null || true)
  if [[ "$result" == Accepted || "$result" == Invalid || "$result" == Rejected ]]; then
    xcrun notarytool log "$submission" --keychain-profile "$GKDL_NOTARY_PROFILE" "$stage/dmg-notary-log.json"
  fi
  [[ "$wait_status" == 0 && "$result" == Accepted ]] || {
    echo "Apple DMG 공증 미완료: ${result:-조회 실패}. 접수 ID: $submission, 진단 폴더: $stage" >&2; exit 1;
  }
  retry xcrun stapler staple "$stage/$dmg"
  xcrun stapler validate "$stage/$dmg"
  spctl --assess --type open --context context:primary-signature --verbose=2 "$stage/$dmg"
fi
(cd "$stage" && shasum -a 256 "$archive" "$dmg" > SHA256SUMS)
rm -r "$stage/dmg" "$stage/module-cache"
rm "$stage/disk-image" "$image"
codesign -d --verbose=4 -r- "$app" > "$stage/signature.txt" 2>&1
cat > "$stage/PACKAGE.txt" <<EOF
gkdl $version / Developer ID ($team)
상태: $status
아키텍처: arm64 + x86_64
소스: $(git rev-parse HEAD)

signed-only는 Apple 공증 완료본이 아니며 macOS 최초 실행이 차단될 수 있습니다.
notarized는 Apple 공증, 티켓 첨부 및 로컬 Gatekeeper 검증을 통과한 패키지입니다.

gkdl은 gksdud와 독립적인 앱입니다. 새 접근성 권한이 필요합니다.
업데이트는 rioald/gkdl의 같은 서명 주체로 배포된 gkdl 앱만 설치합니다.
실제 설치/키보드 동작은 별도 확인이 필요합니다.
EOF
python3 - "$stage/PACKAGE.json" "$status" "$version" "$(git rev-parse HEAD)" <<'PYJSON'
import json, sys
from pathlib import Path
Path(sys.argv[1]).write_text(json.dumps(dict(status=sys.argv[2], version=sys.argv[3], commit=sys.argv[4], repository="rioald/gkdl"), indent=2) + "\n")
PYJSON
rm -r "$stage/build"
mv "$stage" "$destination"
trap - ERR
echo "완료 ($status): $destination/$archive"
