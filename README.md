# gkdl · 하이

**gkdl(하이)** 는 [gksdud](https://github.com/codingnoye/gksdud) 에 다음을 더한 앱입니다.

- **아차차**: 한영을 잘못 선택해 입력한 단어를 단축키로 바로잡기
- **하이 / gkdl**: 한글·영문 입력 상태를 표시하는 메뉴바 스타일
- **Apple Developer ID 서명·공증**: 최초 실행 시 자체 서명 앱의 별도 실행 허용 과정 생략

원작의 한영 전환 기능과 설정·선택지를 유지하면서 필요한 기능을 추가합니다. 원작의 기능과 동작 방식은 아래 [gksdud 설명](#원작-gksdud-readme)에서 확인할 수 있습니다.

<img src="docs/screenshots/general.png" width="384" alt="gkdl 일반 탭: 한영 전환 키와 하이 / gkdl 메뉴바 스타일 설정" />

---

## gkdl 에서 더한 기능

### 1. 아차차

한영 상태를 잘못 선택해 입력했다면 **Shift + Backspace**로 커서 앞 단어를 바로잡으세요.

- `dkssudgktpdy` → `안녕하세요`
- `10qnsenldp` → `10분뒤에`
- 반대 방향도 변환하며, 다른 입력 없이 같은 단축키를 다시 누르면 원문을 복원합니다.
- **아차차** 탭에서 기능을 켜거나 끄고, 단축키를 **Option + Space**로 바꿀 수 있습니다.

<img src="docs/screenshots/achacha.png" width="384" alt="gkdl 아차차 탭: 한영 오입력 바로잡기 기능과 단축키 설정" />

사전이나 AI 없이 두벌식 자판을 기준으로 변환합니다. 단축키를 눌렀을 때만 동작하며, 암호 입력란과 macOS 보안 입력은 제외합니다. 클립보드를 사용하지 않고 입력 내용을 저장·전송하지 않습니다.

일반 입력창, 브라우저, 터미널에서 사용할 수 있습니다. 일부 입력창에서는 동작하지 않을 수 있으며, 터미널에서는 gkdl 실행 중 직접 입력한 현재 단어를 바로잡습니다. 선택 영역이 있다면 해제한 뒤 단어 끝에서 사용하세요.

### 2. 하이 / gkdl 메뉴바 스타일

한글 상태에서는 **하이**, 영문 상태에서는 **gkdl**을 표시합니다. 새 설치의 기본 스타일입니다.

원작의 **한 / dud**, **한 / A**, **KO / EN**, **ㅎuㅎ / dud**도 그대로 선택할 수 있습니다. 기존 선택은 유지하며, 이전 gkdl의 **한 / hi**는 **하이 / gkdl**로 이어집니다.

### 3. Apple Developer ID 서명

정식 배포본은 **Apple Developer ID 서명과 Apple 공증**을 거칩니다. 따라서 최초 실행 시 자체 서명 앱처럼 시스템 설정에서 별도로 실행을 허용하는 과정이 필요하지 않습니다.

## gkdl 설치

**macOS 13 Ventura 이상 · Apple Silicon / Intel 지원**

```sh
brew install --cask rioald/tap/gkdl
```

또는 [gkdl 최신 릴리스](https://github.com/rioald/gkdl/releases/latest)에서 ZIP을 받아 압축을 풀고, `gkdl.app`을 **응용 프로그램** 폴더로 옮기세요.

### 처음 실행할 때

1. 기존 gksdud가 실행 중이면 메뉴에서 정상 종료한 뒤 gkdl을 실행합니다.
2. 메뉴 막대의 **gkdl 아이콘 → 설정**을 엽니다.
3. **접근성 권한 허용**을 누르고, **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 gkdl을 켭니다.
4. gkdl 설정으로 돌아와 **활성화**를 켜고 원하는 한영 전환 키를 선택합니다.
5. **아차차** 탭에서 **아차차 - 한영 잘못 입력 바로잡기**와 단축키를 확인합니다.

앱을 실행해도 창이 보이지 않으면 메뉴 막대에서 설정을 여세요. gksdud와 gkdl의 권한·설정은 별도이며, 두 앱을 동시에 활성화하지 마세요.

### 업데이트와 삭제

설정의 **gkdl(?)** 탭에서 업데이트를 확인하고 설치할 수 있습니다. Homebrew로 설치했다면 다음 명령으로도 업데이트할 수 있습니다.

```sh
brew update
brew upgrade --cask --greedy rioald/tap/gkdl
```

기존 ZIP 설치본을 Homebrew로 관리하거나 설치 오류를 해결하려면 [Homebrew 설치 안내](https://github.com/rioald/homebrew-tap#readme)를 참고하세요.

삭제하기 전에는 메뉴에서 gkdl을 정상 종료해 키보드 설정을 복원하세요. ZIP으로 설치했다면 응용 프로그램 폴더에서 앱을 삭제하고, Homebrew로 설치했다면 `brew uninstall --cask gkdl`을 실행하세요.

## 라이선스

[MIT](LICENSE) · © 2026 rioald

---



&nbsp;

&nbsp;

## 원작 gksdud README

아래는 [gksdud v1.6.0 기준 README 원문](https://github.com/codingnoye/gksdud/blob/54debb68ac31bb11af372d671a730c74b7be2dd4/README.md)입니다. 아래의 설치 명령과 자체 서명 안내는 **원작 gksdud**에 해당하며, **gkdl** 설치는 위 안내를 따라주세요.

---

# gksdud - 씹힘 없고 빠릿빠릿한 Mac 한영 전환

<img width="99" height="109" alt="스크린샷 2026-09-16 오후 11 39 46" src="https://github.com/user-attachments/assets/44f53a4b-4490-475c-80b4-f3fd3b5a8ca8" />

`Karabiner`도, 복잡한 설정도 없이

앱 하나로 **씹힘 없는 한영 전환**을 설정하는 유틸

## 주요 기능

<img width="320" alt="preference demo" src="https://github.com/user-attachments/assets/aec4ba4f-fb0c-4ec8-bee9-d66f570353f3" />

잠깐만 써봐도 체감될 만큼 빠릿빠릿하게 한영 전환됩니다.
- **한영 키 변경**: `우측 ⌘` 등의 키를 선택해 한영 키로 사용
- **딜레이, 키 씹힘 개선**: 기존 방법들의 **딜레이**, **글자 씹힘**, **전환 씹힘** 없는 전환 구현

<img width="502" alt="화면 기록 2026-09-16 오후 10 23 57" src="https://github.com/user-attachments/assets/faf9f36d-bbff-4c5f-8a53-785948fc32cc" />

새로운 방식의, 한영전환 딜레이 없는 꾹 눌러 대소전환 기능입니다.
- **한영키 길게 눌러 대소문자 전환**: 기존 방식과 다르게 누를때 즉시 한영 전환된 후, 길게 유지한다면 대소문자 변환하는 방식으로 **딜레이 없음**
- **한영 전환 대소문자 보존**: 영문 대문자 상태에서 한글로 전환해도 영어로 돌아오면 대문자 유지

<img width="210" alt="menu bar demo" src="https://github.com/user-attachments/assets/9719494e-8f66-4768-859e-c7c4f5cb2db4" />

기존 메뉴바의 입력기 아이콘을 대체해 공간을 절약합니다. 아이콘도 바꿀 수 있어요.

- **특수문자 입력**: 한글 상태에서도 `⌥+문자` 특수문자를 영어처럼 입력하거나, Option 문자 입력을 비활성화
- **다국어 지원 (beta)**: 중국어·일본어 등 다른 입력 소스를 한영 키로 순회하거나, 별도 키로 전환

## 설치

### ⚠️ 주의

현재는 **자체 서명**이므로 macOS가 최초 실행을 차단할 수 있습니다.

실행이 막힌 후 `설정` → `개인정보 보호 및 보안` → `보안`에서 실행을 허용해주세요.

### A. Homebrew로 설치

```sh
brew install --cask codingnoye/tap/gksdud
```

### B. 직접 설치

1. [릴리스 페이지](https://github.com/codingnoye/gksdud/releases/latest)에서 ZIP 압축 파일을 내려받습니다.
2. ZIP 압축을 풀고 안에 있는 `gksdud.app`을 **응용 프로그램** 폴더로 옮깁니다.
3. 응용 프로그램 폴더에서 gksdud를 실행합니다.

## 사용하기

1. `gksdud` 앱을 실행하면 메뉴 바에 아이콘이 표시됩니다.
   1. 기존 입력기 아이콘과 유사한 아이콘을 찾아보세요.
   2. `⌘+드래그`로 위치를 옮길 수 있습니다.
2. **접근성 권한 허용** 후 **활성화**합니다.
3. 상단 입력창에서 한글과 영어를 번갈아 입력하며 테스트해보세요.

## 어떻게 동작하나요?

- **한영 키를 F19로 바꿉니다.** macOS의 키 매핑 기능으로, 선택한 한영 키를 `F19`(기본값)에 연결하고 시스템의 `이전 입력 소스 선택` 단축키도 `F19`로 맞춥니다. 이를 통해 `Caps Lock` 기반 전환의 딜레이를 줄일 수 있습니다. 여기까지는 기존의 `Karabiner`+수동 시스템 설정 방법과 동일합니다.
- **누르자마자 전환합니다.** 한영 키를 누르는 순간 `F19` 키의 누름과 뗌 이벤트를 연달아 발생시킵니다. 빠르게 입력 중 전환 시 한 글자씩 씹히던 문제를 개선합니다.
- **간단한 구현.** 입력 소스를 직접 바꾸거나 입력기를 바꾸지 않습니다. 설정이 꼬이는 문제가 적도록 단순히 키 매핑과 전환 이벤트만으로 동작하게 구현되었습니다.

## 기여

개발 환경과 빌드, 검증 방법은 [기여 안내](CONTRIBUTING.md)를 참고하세요.

## 라이선스

[MIT](LICENSE) ,  © 2026 CodingNoye ,  codingnoye@gmail.com
