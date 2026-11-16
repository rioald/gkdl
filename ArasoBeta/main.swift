import AppKit
import Carbon
import InputMethodKit
import ArasoCore

Resources.directory = Bundle.main.resourceURL
#if TESTS
if CommandLine.arguments.contains("--self-test") {
    runBetaTests()
    exit(0)
}
#endif
guard CommandLine.arguments.dropFirst().allSatisfy({ !$0.hasPrefix("--") }) else { exit(2) }
guard let name = Bundle.main.object(forInfoDictionaryKey: "InputMethodConnectionName") as? String,
      let server = IMKServer(name: name, bundleIdentifier: Bundle.main.bundleIdentifier) else { exit(1) }
_ = BetaRuntime.engine.decide("warmup", context: DecisionContext(japanese: false))
withExtendedLifetime(server) { NSApplication.shared.run() }
