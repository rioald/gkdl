#if ARASO_BETA
import AppKit
import Carbon

enum ArasoBeta {
    static let identifier = "com.zzune.gkdl.beta.inputmethod"
    static let previousKey = "arasoBetaPreviousSource"
    static var directory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Input Methods/하이 Beta 입력기.app")
    }
    static func id(_ source: TISInputSource) -> String? {
        TISGetInputSourceProperty(source, kTISPropertyInputSourceID).map {
            Unmanaged<CFString>.fromOpaque($0).takeUnretainedValue() as String
        }
    }
    static var selected: Bool { currentID == identifier }
    static var currentID: String? { TISCopyCurrentKeyboardInputSource().flatMap { id($0.takeRetainedValue()) } }
    static func source(_ id: String, includingDisabled: Bool = false) -> TISInputSource? {
        let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
        return (TISCreateInputSourceList(filter, includingDisabled)?.takeRetainedValue() as? [TISInputSource])?.first
    }
    static func fail(_ message: String) -> NSError {
        NSError(domain: "gkdl.beta", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
    static func install() throws {
        guard let helper = Bundle.main.builtInPlugInsURL?.appendingPathComponent("HiBetaInput.app"),
              Bundle(url: helper)?.bundleIdentifier == identifier else { throw fail("베타 입력기가 앱에 포함되어 있지 않습니다.") }
        let fm = FileManager.default
        try fm.createDirectory(at: directory.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fm.fileExists(atPath: directory.path) {
            guard Bundle(url: directory)?.bundleIdentifier == identifier else { throw fail("같은 이름의 다른 입력기가 있어 설치를 중단했습니다.") }
            // Never replace the executable of a running input method. Reuse this installed build
            // only when it is byte-for-byte the bundled one; updates require a logout first.
            let binary = "Contents/MacOS/HiBetaInput"
            guard fm.contentsEqual(atPath: helper.appendingPathComponent(binary).path,
                                   andPath: directory.appendingPathComponent(binary).path) else {
                throw fail("이전 베타 입력기가 설치되어 있습니다. 다른 입력 소스로 전환하고 로그아웃한 뒤 기존 베타 입력기를 제거하고 다시 설치해주세요.")
            }
        } else { try fm.copyItem(at: helper, to: directory) }
        guard TISRegisterInputSource(directory as CFURL) == noErr else { throw fail("입력기 등록에 실패했습니다.") }
        guard let input = source(identifier, includingDisabled: true) else {
            throw fail("입력기를 설치했습니다. 시스템 설정 → 키보드 → 입력 소스에서 ‘하이 Beta’를 추가해주세요. 목록에 없으면 로그아웃 후 다시 확인해주세요.")
        }
        guard TISEnableInputSource(input) == noErr else { throw fail("시스템 설정 → 키보드 → 입력 소스에서 ‘하이 Beta’를 추가해주세요.") }
    }
    static func enable(defaults: UserDefaults) throws {
        try install()
        guard let input = source(identifier) else { throw fail("베타 입력기를 찾지 못했습니다.") }
        if let currentID, currentID != identifier { defaults.set(currentID, forKey: previousKey) }
        guard TISSelectInputSource(input) == noErr, selected else { throw fail("베타 입력기로 전환하지 못했습니다. 시스템 입력 메뉴에서 ‘하이 Beta’를 선택해주세요.") }
    }
    static func restore(defaults: UserDefaults) throws {
        guard selected else { defaults.removeObject(forKey: previousKey); return }
        let previous = defaults.string(forKey: previousKey).flatMap { source($0) }
        guard let target = previous ?? source("com.apple.keylayout.ABC") ?? source("com.apple.keylayout.US"),
              TISSelectInputSource(target) == noErr, !selected else { throw fail("기존 입력기로 돌아가지 못했습니다. 시스템 입력 메뉴에서 입력 소스를 선택해주세요.") }
        defaults.removeObject(forKey: previousKey)
    }
}

extension AppDelegate {
    func addArasoBetaControls(to panel: NSStackView) {
        let title = NSTextField(labelWithString: "Araso · Beta")
        title.font = .systemFont(ofSize: 16, weight: .semibold)
        panel.addArrangedSubview(title)
        let description = NSTextField(wrappingLabelWithString: "한영 전환 없이 입력하면 단어마다 언어를 고릅니다.\n영어와 한글이 섞인 단어도 처리합니다.\n\ndkssud → 안녕\ngithubdp → github에\nPDFvkdlf → PDF파일\n\n입력 중 Shift + Backspace: 읽기 바꾸기\nEsc: 현재 단어를 원래 영문 키로 복원\nReturn: 조합 확정, 한 번 더 누르면 줄바꿈\n\n한·영 두벌식 베타입니다. 터미널에서는 영문 키를 그대로 전달합니다. 입력 기록·개인 학습은 저장하지 않습니다.")
        description.font = .systemFont(ofSize: 12)
        panel.addArrangedSubview(description)
        description.widthAnchor.constraint(equalTo: panel.widthAnchor).isActive = true
        for (title, action) in [("베타 입력기 설치하고 사용", #selector(enableArasoBeta)),
                                ("기존 입력기로 돌아가기", #selector(disableArasoBeta)),
                                ("출처·라이선스", #selector(showArasoLicenses))] {
            let button = NSButton(title: title, target: self, action: action)
            button.bezelStyle = .rounded; panel.addArrangedSubview(button)
        }
        let note = NSTextField(wrappingLabelWithString: "다른 한영 입력 도구를 종료한 뒤 시험해주세요. macOS에서 입력 소스 추가를 요구할 수 있습니다. 베타 입력기는 하이의 활성화·일시정지와 별도로 시스템 입력 소스 선택에 따라 동작합니다.")
        note.font = .systemFont(ofSize: 11); note.textColor = .secondaryLabelColor
        panel.addArrangedSubview(note); note.widthAnchor.constraint(equalTo: panel.widthAnchor).isActive = true
    }
    @objc func enableArasoBeta() {
        do { try ArasoBeta.enable(defaults: engine.defaults); window.makeFirstResponder(testInput) }
        catch { report(error) }
    }
    @objc func disableArasoBeta() {
        do { try ArasoBeta.restore(defaults: engine.defaults) }
        catch { report(error) }
    }
    @objc func showArasoLicenses() {
        if let url = Bundle.main.url(forResource: "ThirdPartyNotices", withExtension: "txt") { NSWorkspace.shared.open(url) }
    }
}
#endif
