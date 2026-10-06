# gkdl 개발 안내

Swift/AppKit 기반 macOS 메뉴 막대 앱입니다. 최소 macOS 13, 배포 형식은 arm64 + x86_64 Universal입니다.

프로젝트 작업 지침과 원작 유지·gkdl 확장 원칙은 [AGENTS.md](AGENTS.md)를 따릅니다.

## 검증

```sh
bash -n build.sh scripts/package-release.sh scripts/publish-release.sh signing/verify-update-identity.sh
ruby scripts/test_release.rb
bash build.sh
```

`bash build.sh`는 `outputs/dev/gkdl dev.app`과 개발용 ZIP을 만듭니다. 개발 앱은 `com.zzune.gkdl.dev` 식별자를 사용하므로 정식 앱과 설정·접근성 권한·로그인 항목이 분리됩니다. 창 제목과 메뉴에도 `gkdl dev`를 표시합니다. 처음에는 비활성 상태이며, 입력 기능을 시험할 때는 정식 앱을 정상 종료한 뒤 개발 앱의 접근성 권한과 활성화를 켜세요.

```sh
open "outputs/dev/gkdl dev.app" --args --settings
```

일반 앱에서 테스트 코드를 제외하고, 별도 `gkdl dev tests.app`에 `-D TESTS`를 넣어 자체 테스트를 실행합니다. 한영 전환·잠금화면 복구·아차차 변환·업데이트 검증과 교체 실패 복원 등을 확인합니다. 개발 기본 서명은 ad-hoc이며, 개발 앱은 정식 릴리스 업데이트를 조회하거나 설치하지 않습니다.

정식 앱 빌드는 `GKDL_BUILD_VARIANT=release bash build.sh`로 구분합니다. 아래 배포 스크립트는 이 값을 자동으로 지정하며, 기존 `gkdl.app` 이름·식별자·배포 파일명을 유지합니다.

실제 입력과 접근성은 별도 확인이 필요합니다. [tests/README.md](tests/README.md)의 절차를 참고하세요. 실행 중인 다른 입력 전환 앱은 먼저 정상 종료하세요.

## 배포

[signing/README.md](signing/README.md)의 로컬 Developer ID/공증 절차를 사용합니다. CI는 빌드·테스트만 수행하며, 비공증 빌드를 공개하지 않습니다. 최초 독립 버전은 1.0.0입니다.

릴리스 설명에는 해당 버전의 변경사항만 적습니다. 설치·업데이트·권한 설정·사용법·라이선스 안내는 README에서 관리합니다. 인증서 이름·팀 ID·공증 절차 등 배포 내부 정보는 개발 문서에서 관리합니다. 릴리스 설명의 `## 요약` 제목은 앱의 업데이트 안내에서 사용하므로 유지합니다.

원본 변경사항은 `upstream`에서 명시적으로 통합합니다. 원본 태그를 gkdl 배포 태그로 사용하지 마세요. gkdl의 `origin`은 `https://github.com/rioald/gkdl.git`입니다.
