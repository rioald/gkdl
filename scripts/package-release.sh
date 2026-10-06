#!/bin/bash
# 로컬 키체인의 Developer ID로 빌드한다. 설치하거나 공개하지 않는다.
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
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo '버전은 X.Y.Z 형식이어야 합니다.' >&2; exit 1; }
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
GKDL_BUILD_VARIANT=release GKDL_SIGN_MODE=developer-id GKDL_SIGN_IDENTITY="$identity" GKDL_OUTPUT_DIR="$stage/build" bash build.sh
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
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
  codesign --verify --deep --strict --all-architectures -R "$requirement" "$app"
  spctl --assess --type execute --verbose=2 "$app"
fi

# 공증 티켓이 첨부된 앱을 다시 압축해야 오프라인에서도 티켓을 사용할 수 있다.
archive="gkdl-$version-macos-universal.zip"
ditto -c -k --keepParent --norsrc "$app" "$stage/$archive"
(cd "$stage" && shasum -a 256 "$archive" > SHA256SUMS)
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
