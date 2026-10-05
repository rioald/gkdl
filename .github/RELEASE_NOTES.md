## 요약

- **gkdl(하이) 첫 릴리스**: 원하는 키로 한영을 전환하고, 잘못 입력한 단어를 단축키로 바로잡습니다.
- **아차차**: `dkssudgktpdy`를 입력하고 **Shift + Backspace**를 누르면 `안녕하세요`로 바로잡습니다.
- 사전 없이 두벌식 기준으로 변환하며, `10qnsenldp` → `10분뒤에`처럼 숫자가 섞인 단어도 지원합니다.
- 같은 단축키를 바로 다시 누르면 원문을 복원합니다. 암호 입력은 제외하며 입력 내용을 저장·전송하지 않습니다.
- Caps Lock·오른쪽 Command·Shift + Space 등 원하는 한영 전환 키를 설정할 수 있습니다.

## 설치

**macOS 13 이상 · Apple Silicon / Intel 지원**

```sh
brew install --cask rioald/tap/gkdl
```

또는 첨부된 `gkdl-1.0.0-macos-universal.zip`을 풀어 `gkdl.app`을 **응용 프로그램** 폴더에 옮기세요.

## 처음 실행할 때

1. 기존 gksdud는 정상 종료한 뒤 gkdl을 실행하세요.
2. 메뉴 막대의 **한/hi → 설정**에서 **접근성 권한 허용**을 누르세요.
3. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 gkdl을 켠 뒤, gkdl 설정의 **활성화**를 켜세요.
4. **아차차** 탭에서 **단축키로 한영 잘못 입력 바로잡기**를 켜세요. 기본 단축키는 **Shift + Backspace**입니다.

앱을 실행해도 창이 보이지 않으면 메뉴 막대에서 설정을 여세요. 기존 gksdud와는 권한과 설정이 별도입니다.

자세한 사용법과 업데이트 방법은 [사용 안내](https://github.com/rioald/gkdl#readme)를 참고하세요.

[gksdud](https://github.com/codingnoye/gksdud) 기반 · MIT License · © 2026 CodingNoye · gkdl 변경사항 © 2026 rioald.
