# gkdl · 하이

macOS에서 한영을 전환하고, 잘못 입력한 단어를 단축키로 바로잡는 메뉴 막대 앱입니다.
`gkdl`을 두벌식 한글로 입력하면 **하이**가 됩니다.

[gksdud](https://github.com/codingnoye/gksdud)를 기반으로 한영 전환과 **아차차**를 제공합니다.

## 아차차

한영 상태를 잘못 선택해 입력했다면 **Shift + Backspace**를 누르세요.

- `dkssudgktpdy` → **Shift + Backspace** → `안녕하세요`
- `10qnsenldp` → **Shift + Backspace** → `10분뒤에`
- 반대 방향도 변환하며, 바로 뒤에 같은 단축키를 누르면 원문을 복원합니다.
- 아차차 탭에서 켜고, 단축키를 **Option + Space**로 바꿀 수도 있습니다.

사전이나 AI 없이 두벌식 자판을 기준으로 변환합니다. 새 단어·이름·숫자가 섞인 단어도 사용할 수 있습니다. 입력을 자동으로 고치지 않으며, 단축키를 눌렀을 때만 바로잡습니다.

일반 입력창, 브라우저, 터미널에서 사용할 수 있습니다. 일부 입력창에서는 동작하지 않을 수 있으며, 터미널에서는 gkdl 실행 중 직접 입력한 현재 단어를 바로잡습니다.

암호 입력란과 macOS 보안 입력 중에는 동작하지 않습니다. 클립보드를 사용하지 않으며 입력 내용을 저장하거나 전송하지 않습니다.

## 한영 전환

- Caps Lock·오른쪽 Command 등 키보드별 전환 키 설정
- Shift + Space 등 조합 키로 전환
- 대문자 상태, 메뉴 막대 입력 상태 표시
- Option 특수문자와 추가 입력 소스 설정

설정 창의 입력란에서 바로 테스트할 수 있습니다.

## 설치

**macOS 13 Ventura 이상 · Apple Silicon / Intel 지원**

Homebrew로 설치할 수 있습니다.

```sh
brew install --cask rioald/tap/gkdl
```

또는 [최신 릴리스](https://github.com/rioald/gkdl/releases/latest)에서 ZIP을 받아 압축을 풀고, `gkdl.app`을 **응용 프로그램** 폴더로 옮기세요.

### 처음 실행할 때

1. 기존 gksdud가 실행 중이면 메뉴에서 정상 종료한 뒤 gkdl을 실행합니다.
2. 메뉴 막대의 **한/hi → 설정**을 엽니다.
3. **접근성 권한 허용**을 누르고, **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 gkdl을 켭니다.
4. gkdl 설정으로 돌아와 **활성화**를 켜고 원하는 한영 전환 키를 선택합니다.
5. **아차차** 탭에서 **단축키로 한영 잘못 입력 바로잡기**를 켭니다.

앱을 실행해도 창이 보이지 않으면 메뉴 막대에서 설정을 여세요. 입력 기능이 동작하지 않으면 접근성 권한과 **활성화**가 모두 켜져 있는지 확인하세요.

gksdud를 사용했더라도 gkdl의 권한과 설정은 따로 지정해야 합니다. 두 앱을 동시에 활성화하지 마세요.

## 업데이트와 삭제

설정의 **gkdl** 탭에서 업데이트를 확인하고, 새 버전이 있으면 설치할 수 있습니다.

Homebrew로 설치했다면 다음 명령으로도 업데이트할 수 있습니다.

```sh
brew update
brew upgrade --cask --greedy rioald/tap/gkdl
```

기존 ZIP 설치본을 Homebrew로 관리하거나 설치 오류를 해결하려면 [Homebrew 설치 안내](https://github.com/rioald/homebrew-tap#readme)를 참고하세요.

삭제하기 전에는 메뉴에서 gkdl을 정상 종료해 키보드 설정을 복원하세요. ZIP으로 설치했다면 응용 프로그램 폴더에서 앱을 삭제하고, Homebrew로 설치했다면 `brew uninstall --cask gkdl`을 실행하세요.

## 개발 참여

빌드·테스트·배포 방법은 [개발 안내](CONTRIBUTING.md)를 참고하세요.

## 라이선스와 출처

[MIT License](LICENSE). 원본 gksdud: © 2026 CodingNoye. gkdl 변경사항: © 2026 rioald.
원본의 저작권·라이선스를 소스와 앱에 함께 포함합니다. 자세한 출처는 [NOTICE](NOTICE)에 있습니다.
