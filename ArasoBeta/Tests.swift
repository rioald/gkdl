#if TESTS
import Foundation
import ArasoCore

func runBetaTests() {
    func check(_ condition: @autoclosure () -> Bool, _ name: String) {
        guard condition() else { fputs("FAILED: \(name)\n", stderr); exit(1) }
    }
    let resources = [Resources.englishWords, Resources.englishAcronyms, Resources.koreanWords,
                     Resources.koreanSyllables, Resources.koreanVocabulary]
    check(resources.allSatisfy { $0?.path.hasPrefix(Bundle.main.bundlePath + "/Contents/Resources/") == true }, "bundled data")
    check(EnglishModel.shared.wordCount > 100_000, "English vocabulary")
    for (keys, expected) in [("hello", "hello"), ("dkssud", "안녕"), ("dkssudgktpdy", "안녕하세요"),
                             ("githubdp", "github에"), ("PDFvkdlf", "PDF파일")] {
        var word = BetaComposition(engine: BetaRuntime.engine)
        for key in keys { check(word.append(key), "append") }
        check(word.text == expected, "\(keys) -> \(expected), got \(word.text)")
        word.cycle()
        check(word.text != expected, "manual alternate")
        check(word.keys == keys, "raw keys retained for escape")
        word.clear()
        check(word.keys.isEmpty && word.text.isEmpty, "clear context")
    }
    var word = BetaComposition(engine: BetaRuntime.engine)
    for key in "dkssud" { _ = word.append(key) }
    word.delete()
    check(word.keys == "dkssu", "delete last keystroke")
    word.clear()
    for _ in 0..<BetaComposition.limit { check(word.append("a"), "bounded word") }
    check(!word.append("a") && word.keys.count == BetaComposition.limit, "word limit")
    check(!word.append("한"), "reject non-ASCII")
    check(BetaRuntime.isLiteralApp("com.apple.Terminal") && BetaRuntime.isLiteralApp(nil), "password-sensitive clients")
    check(!BetaRuntime.isLiteralApp("com.apple.TextEdit"), "normal client")
    print("Araso beta: bundled resources, language decisions, mixed words, cycling, deletion and bounds passed")
    runBetaClientTests()
}
#endif
