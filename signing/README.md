# gkdl 서명과 공증

정식 배포 식별자는 `com.zzune.gkdl`, Apple 팀 ID는 `KTC97BHY7R`입니다.
개인 키·인증서 내보내기 파일·암호·API 키는 저장소에 넣지 않습니다.

## 준비

로컬 키체인에 `Developer ID Application: TWENTYOZ (KTC97BHY7R)` 인증서와 해당 개인 키가 필요합니다. 인증서 이름은 Apple에 등록된 서명 주체이므로 앱 이름·식별자와 별개이며 임의로 바꾸지 않습니다. 이 이름은 서명 정보에 남습니다. 키체인이 서명 허용을 요청하면 사용자가 직접 macOS 창에서 승인합니다.

Apple 공증 프로필은 로컬 터미널에서 대화형으로 등록합니다. 암호를 셸 명령이나 채팅에 넣지 마세요.

```sh
xcrun notarytool store-credentials gkdl-notary
```

Apple ID 인증은 앱 암호와 위 팀 ID를 사용합니다. 이미 프로필이 있으면 그 이름을 `GKDL_NOTARY_PROFILE`에 지정합니다.

## 패키징

버전은 `Info.plist`의 `CFBundleShortVersionString`, 빌드 번호는 `CFBundleVersion`입니다. 정식 패키징 전에 소스를 커밋합니다.

```sh
GKDL_NOTARY_PROFILE=gkdl-notary bash scripts/package-release.sh --notarize
```

스크립트는 다음을 수행합니다.

1. 인증서와 공증 인증을 확인합니다.
2. Universal 앱을 빌드하고 자체 테스트를 실행합니다.
3. Hardened Runtime 및 보안 타임스탬프로 서명하고 팀·앱 ID를 검증합니다.
4. Apple에 ZIP을 제출하고 `Accepted` 상태를 확인합니다.
5. 공증 티켓을 앱에 첨부하고 `stapler validate`, `codesign`, `spctl` 검증을 수행합니다.
6. 티켓이 포함된 앱을 다시 압축하고 `SHA256SUMS`와 진단 기록을 저장합니다.

결과는 `outputs/packages/VERSION-notarized/`에 생성됩니다. 기존 결과는 덮어쓰지 않습니다. 중단되면 출력된 임시 폴더의 `notary-submission.json` 접수 ID로 상태를 조회할 수 있습니다.

`--signed-only`는 서명 검사용이며 Apple 공증 완료본이 아닙니다. 정식 공개 스크립트는 이 패키지를 거부합니다.

## 공개와 설치 확인

```sh
ruby scripts/prepare-release.rb outputs/packages/1.0.0-notarized/gkdl-1.0.0-macos-universal.zip
bash scripts/publish-release.sh outputs/packages/1.0.0-notarized .github/RELEASE_NOTES.md
```

공개 스크립트는 패키지의 앱 ID·팀·버전·아키텍처·라이선스·공증 티켓·Gatekeeper·체크섬과 소스 커밋을 다시 확인하고, `rioald/gkdl`에 소스·태그·릴리스 파일을 올립니다. 기존 태그나 릴리스 파일은 강제로 교체하지 않습니다.

공개 후 첨부 파일을 다시 내려받아 같은 검증을 실행하고, 응용 프로그램 폴더에서 실행과 접근성 권한을 확인합니다. 업데이트 후 권한 유지와 실제 브라우저·터미널 입력은 별도의 실행 검증입니다.

## Homebrew 갱신

새 정식 릴리스 검증 후 [rioald/homebrew-tap](https://github.com/rioald/homebrew-tap)의 `Casks/gkdl.rb`에서 `version`과 공개 ZIP의 `sha256`을 갱신합니다. Homebrew style·audit·livecheck·fetch를 확인하고 커밋·푸시합니다. Cask 갱신은 자동화되어 있지 않습니다.

공식 참고: [Developer ID](https://developer.apple.com/developer-id/), [Apple notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).
