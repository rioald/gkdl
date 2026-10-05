# gkdl 개발 안내

Swift/AppKit 기반 macOS 메뉴 막대 앱입니다. 최소 macOS 13, 배포 형식은 arm64 + x86_64 Universal입니다.

## 원칙

- 단축키로 요청한 경우에만 한영 오입력을 변환합니다. 자동 교정·사전·AI·네트워크 변환을 추가하지 않습니다.
- 암호/보안 입력은 제외하며 입력 기록을 저장·전송하지 않습니다.
- 일반 타이핑 중 전체 문서를 읽지 않습니다. 커서·선택·문맥이 불확실하면 입력을 보존합니다.
- 키보드 매핑을 바꾸는 기능은 정상 종료와 실패 시 기존 시스템 설정을 복원해야 합니다.
- 원본 프로젝트의 MIT 저작권과 라이선스는 유지합니다.

## 검증

```sh
bash -n build.sh scripts/package-release.sh scripts/publish-release.sh signing/verify-update-identity.sh
ruby scripts/test_release.rb
bash build.sh
```

`build.sh`는 배포 앱에서 테스트 코드를 제외하고, 별도의 테스트 앱에 `-D TESTS`를 넣어 자체 테스트를 실행합니다. 한영 전환·잠금화면 복구·아차차 변환·업데이트 검증과 교체 실패 복원 등을 확인합니다. 개발 기본 서명은 ad-hoc이며 이 앱은 자동 업데이트를 지원하지 않습니다.

실제 입력과 접근성은 별도 확인이 필요합니다. [tests/README.md](tests/README.md)의 절차를 참고하세요. 실행 중인 다른 입력 전환 앱은 먼저 정상 종료하세요.

## 배포

[signing/README.md](signing/README.md)의 로컬 Developer ID/공증 절차를 사용합니다. CI는 빌드·테스트만 수행하며, 비공증 빌드를 공개하지 않습니다. 최초 독립 버전은 1.0.0입니다.

릴리스 설명과 README에는 일반 사용자가 알아야 할 기능, 변경사항, 설치·권한 설정, 사용법을 적습니다. 인증서 이름·팀 ID·공증 절차 등 배포 내부 정보는 개발 문서에서 관리합니다. 릴리스 설명의 `## 요약` 제목은 앱의 업데이트 안내에서 사용하므로 유지합니다.

원본 변경사항은 `upstream`에서 명시적으로 통합합니다. 원본 태그를 gkdl 배포 태그로 사용하지 마세요. gkdl의 `origin`은 `https://github.com/rioald/gkdl.git`입니다.
