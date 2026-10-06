## 요약

- 앱 아이콘을 영문 **gkdl** 배지 모양으로 바꿨습니다.
- **하이 / gkdl** 메뉴 막대 아이콘을 조금 작게 다듬었습니다.
- **gkdl(?)** 탭에서는 정사각형 배경 없이 gkdl 배지를 표시합니다.
- 메뉴 상단의 `hi` 아이콘을 제거해 **gkdl** 이름만 표시합니다.
- 사용 안내에 일반·아차차 탭의 창 전체 스크린샷을 추가했습니다.

## 업데이트

설정의 **gkdl(?)** 탭에서 업데이트를 확인하고 설치하세요. Homebrew로 설치했다면 다음 명령을 사용하세요.

```sh
brew update
brew upgrade --cask --greedy rioald/tap/gkdl
```

## 설치

**macOS 13 이상 · Apple Silicon / Intel 지원**

```sh
brew install --cask rioald/tap/gkdl
```

또는 첨부된 `gkdl-1.0.1-macos-universal.zip`을 풀어 `gkdl.app`을 **응용 프로그램** 폴더에 옮기세요. Apple Developer ID 서명과 Apple 공증을 완료한 배포본입니다.

## 처음 실행할 때

1. 기존 gksdud는 정상 종료한 뒤 gkdl을 실행하세요.
2. 메뉴 막대의 **하이 / gkdl → 설정**에서 **접근성 권한 허용**을 누르세요.
3. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 gkdl을 켠 뒤, gkdl 설정의 **활성화**를 켜세요.
4. **아차차** 탭에서 **아차차 - 한영 잘못 입력 바로잡기**를 켜세요. 기본 단축키는 **Shift + Backspace**입니다.

앱을 실행해도 창이 보이지 않으면 메뉴 막대에서 설정을 여세요. 기존 gksdud와는 권한과 설정이 별도입니다.

자세한 사용법과 업데이트 방법은 [사용 안내](https://github.com/rioald/gkdl#readme)를 참고하세요.

[gksdud](https://github.com/codingnoye/gksdud) 기반 · MIT License · © 2026 CodingNoye · gkdl 변경사항 © 2026 rioald.
