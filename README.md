# gkdl · 하이

macOS에서 한영을 전환하고, 잘못 입력한 단어를 단축키로 바로잡는 메뉴 막대 앱입니다.
`gkdl`을 두벌식 한글로 입력하면 **하이**가 됩니다.

[gksdud](https://github.com/codingnoye/gksdud)를 기반으로 만든 독립 배포 앱입니다. 원본의 한영 전환 기능에 **아차차**를 더하고, 앱 이름·설정·업데이트 경로를 분리했습니다.

## 아차차

한영 상태를 잘못 선택해 입력했다면 **Shift + Backspace**를 누르세요.

- `dkssudgktpdy` → **Shift + Backspace** → `안녕하세요`
- `10qnsenldp` → **Shift + Backspace** → `10분뒤에`
- 반대 방향도 변환하며, 바로 뒤에 같은 단축키를 누르면 원문을 복원합니다.
- 아차차 탭에서 켜고, 단축키를 **Option + Space**로 바꿀 수도 있습니다.

사전이나 AI 없이 두벌식 자판을 기준으로 변환합니다. 새 단어·이름·숫자가 섞인 단어도 사용할 수 있습니다. 입력을 자동으로 고치지 않으며, 단축키를 눌렀을 때만 바로잡습니다.

일반 입력창, 브라우저, 터미널을 지원합니다. 암호 입력란과 macOS 보안 입력 중에는 동작하지 않습니다. 클립보드를 사용하지 않으며 입력 내용을 저장하거나 전송하지 않습니다. 입력창이 필요한 읽기·편집 기능을 제공하지 않거나 커서 위치가 불확실하면 변경하지 않습니다. 터미널에서는 실행 중 직접 입력한 현재 단어를 기준으로 동작합니다.

## 한영 전환

- Caps Lock·오른쪽 Command 등 키보드별 전환 키 설정
- Shift + Space 등 조합 키로 전환
- 대문자 상태, 메뉴 막대 입력 상태 표시
- Option 특수문자와 추가 입력 소스 설정

설정 창의 입력란에서 바로 테스트할 수 있습니다.

## 설치

**macOS 13 Ventura 이상 · Apple Silicon / Intel Universal**

1. [Releases](https://github.com/rioald/gkdl/releases)에서 `gkdl-VERSION-macos-universal.zip`을 받습니다.
2. 압축을 풀고 `gkdl.app`을 **응용 프로그램** 폴더로 옮깁니다.
3. 기존 gksdud가 실행 중이면 메뉴에서 정상 종료한 뒤 gkdl을 실행합니다.
4. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 gkdl을 허용합니다.
5. 원하는 한영 전환 키와 아차차를 켭니다.

정식 릴리스는 **TWENTYOZ Developer ID 서명 → Apple 공증 → 티켓 첨부 → Gatekeeper 검증**을 통과한 패키지만 게시합니다. 개발용 빌드와 공증 전 패키지는 정식 릴리스가 아닙니다.

gkdl의 앱 ID는 `kr.twentyoz.gkdl`입니다. 기존 gksdud의 설정·접근성 권한을 가져오지 않습니다. 두 앱은 시스템 키보드 설정을 함께 제어하므로 동시에 활성화하지 마세요. 삭제하기 전에는 앱을 정상 종료해 키보드 설정을 복원하세요.

업데이트는 `rioald/gkdl`의 릴리스에서 확인합니다. 파일 체크섬, 앱 ID, 버전, 현재 설치본과 같은 서명 주체인지 검증한 뒤 설치합니다. 원본 gksdud로 교체되지 않습니다.

## 개발과 배포

```sh
# 개발용 Universal 빌드 + 자체 테스트 (배포용 인증 없음)
bash build.sh

# 로컬 키체인의 TWENTYOZ Developer ID로 서명만 수행
bash scripts/package-release.sh --signed-only

# Apple 공증까지 수행 (소스 커밋 및 키체인 프로필 필요)
GKDL_NOTARY_PROFILE=gkdl-notary bash scripts/package-release.sh --notarize

# 검증된 패키지를 GitHub에 공개
bash scripts/publish-release.sh outputs/packages/1.0.0-notarized .github/RELEASE_NOTES.md
```

키체인 프로필 등록, 검증 방법은 [signing/README.md](signing/README.md), 개발 규칙은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고하세요.

## 라이선스와 출처

[MIT License](LICENSE). 원본 gksdud: © 2026 CodingNoye. gkdl 변경사항: © 2026 TWENTYOZ.
원본의 저작권·라이선스를 소스와 앱에 함께 포함합니다. 자세한 출처는 [NOTICE](NOTICE)에 있습니다.
