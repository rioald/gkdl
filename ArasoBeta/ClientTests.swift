#if TESTS
import AppKit
import Carbon
import InputMethodKit

/// An IMK client that rejects document reads, so the host's input-preservation boundary is tested.
private final class BetaTestClient: NSObject, IMKTextInput {
    var value = ""
    var selection = NSRange(location: 0, length: 0)
    var marked = NSRange(location: NSNotFound, length: 0)
    var applicationID = "com.apple.TextEdit"
    var documentReads = 0
    func replace(_ object: Any!, range: NSRange) -> String {
        let text = (object as? String) ?? (object as? NSAttributedString)?.string ?? ""
        let target = range.location != NSNotFound ? range : marked.location != NSNotFound ? marked : selection
        value = (value as NSString).replacingCharacters(in: target, with: text)
        selection = NSRange(location: target.location + (text as NSString).length, length: 0)
        return text
    }
    func insertText(_ string: Any!, replacementRange: NSRange) { _ = replace(string, range: replacementRange); marked = NSRange(location: NSNotFound, length: 0) }
    func setMarkedText(_ string: Any!, selectionRange: NSRange, replacementRange: NSRange) {
        let start = marked.location != NSNotFound ? marked.location : selection.location
        let text = replace(string, range: replacementRange)
        marked = text.isEmpty ? NSRange(location: NSNotFound, length: 0) : NSRange(location: start, length: (text as NSString).length)
        selection = NSRange(location: start + selectionRange.location, length: selectionRange.length)
    }
    func selectedRange() -> NSRange { selection }
    func markedRange() -> NSRange { marked }
    func attributedSubstring(from range: NSRange) -> NSAttributedString! { documentReads += 1; return nil }
    func length() -> Int { documentReads += 1; return NSNotFound }
    func characterIndex(for point: NSPoint, tracking mappingMode: IMKLocationToOffsetMappingMode, inMarkedRange: UnsafeMutablePointer<ObjCBool>!) -> Int { NSNotFound }
    func attributes(forCharacterIndex index: Int, lineHeightRectangle lineRect: UnsafeMutablePointer<NSRect>!) -> [AnyHashable: Any]! { [:] }
    func validAttributesForMarkedText() -> [Any]! { [] }
    func overrideKeyboard(withKeyboardNamed keyboardUniqueName: String!) {}
    func selectMode(_ modeIdentifier: String!) {}
    func supportsUnicode() -> Bool { true }
    func bundleIdentifier() -> String! { applicationID }
    func windowLevel() -> CGWindowLevel { 0 }
    func supportsProperty(_ property: TSMDocumentPropertyTag) -> Bool { false }
    func uniqueClientIdentifierString() -> String! { "beta-test-client" }
    func string(from range: NSRange, actualRange: NSRangePointer!) -> String! { documentReads += 1; return nil }
    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer!) -> NSRect { .zero }
}

func runBetaClientTests() {
    func check(_ condition: @autoclosure () -> Bool, _ name: String) {
        guard condition() else { fputs("FAILED IMK: \(name)\n", stderr); exit(1) }
    }
    func event(_ text: String, code: UInt16 = 0, flags: NSEvent.ModifierFlags = []) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
                        windowNumber: 0, context: nil, characters: text, charactersIgnoringModifiers: text,
                        isARepeat: false, keyCode: code)!
    }
    func make() -> (BetaInputHandler, BetaTestClient) {
        let client = BetaTestClient()
        let controller = BetaInputHandler()
        controller.secureInput = { false }
        return (controller, client)
    }
    for (keys, expected) in [("dkssud", "안녕"), ("githubdp", "github에"), ("PDFvkdlf", "PDF파일")] {
        let (controller, client) = make()
        for key in keys { check(controller.handle(event(String(key)), client: client), "letter consumed") }
        check(client.value == expected, "marked word \(keys)")
        check(!controller.handle(event(" ", code: 49), client: client), "space goes to app")
        check(client.value == expected && client.marked.location == NSNotFound, "word committed")
        check(client.documentReads == 0, "no document access")
    }
    do {
        let (controller, client) = make()
        for key in "dkssud" { _ = controller.handle(event(String(key)), client: client) }
        check(controller.handle(event("", code: 53), client: client), "escape consumed")
        check(client.value == "dkssud", "escape restores raw keys")
    }
    do {
        let (controller, client) = make()
        for key in "dkssud" { _ = controller.handle(event(String(key)), client: client) }
        check(controller.handle(event("", code: 51, flags: .shift), client: client), "cycle consumed")
        check(client.value == "dkssud", "cycle alternative")
        check(controller.handle(event("", code: 36), client: client), "return commits first")
        check(!controller.handle(event("", code: 36), client: client), "second return reaches app")
    }
    do {
        let (controller, client) = make()
        for key in "dkssud" { _ = controller.handle(event(String(key)), client: client) }
        client.selection = NSRange(location: 0, length: 0)
        check(!controller.handle(event("a"), client: client) && client.value == "안녕", "caret moved preserves text")
        controller.finish()
        check(client.value == "안녕", "stale composition not reinserted")
    }
    do {
        let (controller, client) = make()
        client.value = "existing"; client.selection = NSRange(location: 0, length: 8)
        check(!controller.handle(event("d"), client: client) && client.value == "existing", "selection preserved")
        client.applicationID = "com.apple.Terminal"; client.selection = NSRange(location: 8, length: 0)
        check(!controller.handle(event("d"), client: client), "terminal passes through")
    }
    do {
        let (controller, client) = make()
        controller.secureInput = { true }
        check(!controller.handle(event("d"), client: client) && client.value.isEmpty, "secure input rejected")
        controller.secureInput = { false }
        for key in "dkssud" { _ = controller.handle(event(String(key)), client: client) }
        client.value = "password"; client.marked = NSRange(location: NSNotFound, length: 0)
        client.selection = NSRange(location: 8, length: 0)
        controller.secureInput = { true }; controller.finish()
        check(client.value == "password", "secure transition never commits buffered text")
    }
    do {
        let (controller, client) = make()
        for key in "dkssud" { _ = controller.handle(event(String(key)), client: client) }
        client.selection = NSRange(location: 0, length: 0)
        controller.finish()
        check(client.value == "안녕", "focus change does not duplicate word")
    }
    print("Araso beta IMK client: composition, commit, alternatives, restore, caret and selection preservation passed")
}
#endif
