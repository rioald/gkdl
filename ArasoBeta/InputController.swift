import AppKit
import Carbon
import InputMethodKit
import ArasoCore

enum BetaRuntime {
    static let engine = SplittingEngine(base: HeuristicEngine(), english: .shared)
    // Shell password prompts need not enable macOS Secure Input. Keep these clients literal.
    static let literalApps: Set<String> = ["com.apple.Terminal", "com.googlecode.iterm2",
        "com.mitchellh.ghostty", "dev.warp.Warp-Stable", "org.alacritty", "net.kovidgoyal.kitty"]
    static func isLiteralApp(_ id: String?) -> Bool {
        guard let id else { return true }
        return literalApps.contains(id) || id.hasPrefix("com.apple.loginwindow")
    }
}

@objc(HiBetaInputController)
final class HiBetaInputController: IMKInputController {
    private let input = BetaInputHandler()
    override func recognizedEvents(_ sender: Any!) -> Int {
        Int(NSEvent.EventTypeMask.keyDown.rawValue | NSEvent.EventTypeMask.flagsChanged.rawValue)
    }
    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        input.reset()
        (sender as? IMKTextInput)?.overrideKeyboard(withKeyboardNamed: "com.apple.keylayout.US")
    }
    override func deactivateServer(_ sender: Any!) {
        input.finish()
        super.deactivateServer(sender)
    }
    override func commitComposition(_ sender: Any!) { input.finish() }
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool { input.handle(event, client: sender) }
}

// IMK owns the controller; this adapter can also be exercised with a protocol-conforming client.
final class BetaInputHandler {
    var secureInput: () -> Bool = { IsSecureEventInputEnabled() }
    private var composition = BetaComposition(engine: BetaRuntime.engine)
    private var literal = false
    private var uppercase = false
    private var markedClient: IMKTextInput?
    private static let noRange = NSRange(location: NSNotFound, length: 0)

    func reset() { composition.clear(); literal = false; markedClient = nil }
    func finish() { commit(); literal = false }

    private func commit(raw: Bool = false) {
        guard !composition.keys.isEmpty else { return }
        let text = raw ? composition.keys : composition.text
        let input = markedClient
        composition.clear(); markedClient = nil
        guard !secureInput(), let input else { return }
        let marked = input.markedRange(), selection = input.selectedRange()
        guard marked.location != NSNotFound, marked.length > 0,
              selection.location != NSNotFound, selection.length == 0,
              selection.location == NSMaxRange(marked) else { return }
        // Use the client that owns this marked text, never a new focused field.
        input.insertText(uppercase ? text.uppercased() : text, replacementRange: Self.noRange)
    }
    private func mark(_ input: IMKTextInput) {
        markedClient = input
        let text = uppercase ? composition.text.uppercased() : composition.text
        input.setMarkedText(text, selectionRange: NSRange(location: (text as NSString).length, length: 0),
                            replacementRange: Self.noRange)
        if composition.keys.isEmpty { markedClient = nil }
    }
    func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, let input = sender as? IMKTextInput else { return false }
        // IMK normally bypasses password fields. Also reject every secure-input session.
        guard !secureInput(), !BetaRuntime.isLiteralApp(input.bundleIdentifier()) else {
            composition.clear(); markedClient = nil; literal = false
            return false
        }
        if event.type == .flagsChanged {
            if !event.modifierFlags.intersection([.command, .control, .option]).isEmpty { commit() }
            return false
        }
        guard event.type == .keyDown else { return false }
        if !composition.keys.isEmpty {
            let range = input.markedRange(), selection = input.selectedRange()
            // The caret moved or the client stopped tracking our composition: leave its text alone.
            guard range.location != NSNotFound, range.length > 0,
                  selection.location != NSNotFound, selection.length == 0,
                  selection.location == NSMaxRange(range) else {
                composition.clear(); markedClient = nil; literal = false
                return false
            }
        }
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        if event.keyCode == 51 && modifiers == .shift && !composition.keys.isEmpty {
            composition.cycle(); mark(input); return true
        }
        guard modifiers.intersection([.command, .control, .option]).isEmpty else {
            commit(); literal = false; return false
        }
        if event.keyCode == 53 { // Escape recovers the exact keys of the current word.
            let hadWord = !composition.keys.isEmpty
            commit(raw: true); literal = false; return hadWord
        }
        if event.keyCode == 51 {
            guard !composition.keys.isEmpty else { literal = false; return false }
            composition.delete(); mark(input); return true
        }
        if [36, 76].contains(event.keyCode) {
            let hadWord = !composition.keys.isEmpty
            commit(); literal = false; return hadWord
        }
        guard let characters = event.characters, characters.count == 1, let character = characters.first,
              character.isASCII, !character.isNewline, !character.isWhitespace || character == " " else {
            commit(); literal = false; return false
        }
        if character == " " { commit(); literal = false; return false }
        if literal { return false }
        // Paths, URLs, email and identifiers stay literal from their first punctuation onward.
        if "/:@._~\\".contains(character) || character.isNumber {
            commit(raw: true); literal = true; return false
        }
        if character.isLetter {
            // Do not take over an existing selection. IMK owns only the word it started itself.
            if composition.keys.isEmpty {
                let selection = input.selectedRange()
                guard selection.location != NSNotFound, selection.length == 0 else { return false }
            }
            let caps = event.modifierFlags.contains(.capsLock) && !event.modifierFlags.contains(.shift)
            if !composition.keys.isEmpty && caps != uppercase { commit() }
            uppercase = caps
            let key = caps ? Character(character.lowercased()) : character
            guard composition.append(key) else { commit(raw: true); literal = true; return false }
            mark(input); return true
        }
        commit(); return false
    }
}
