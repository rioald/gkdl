import AppKit

enum MenuBarIconStyle: String, CaseIterable {
    // Keep the original gksdud choices first; persisted names do not depend on menu order.
    case hanDud, hanA, languageCodes, character, hanHi, gkdl

    var title: String {
        self == .character ? "ㅎuㅎ / dud" : "\(label(korean: true)) / \(label(korean: false))"
    }
    func label(korean: Bool) -> String {
        switch self {
        case .hanDud: return korean ? "한" : "dud"
        case .hanA: return korean ? "한" : "A"
        case .languageCodes: return korean ? "KO" : "EN"
        case .character: return korean ? "ㅎuㅎ" : "dud"
        case .hanHi: return korean ? "한" : "hi"
        case .gkdl: return korean ? "하이" : "gkdl"
        }
    }
    var width: CGFloat { self == .gkdl ? 32 : 22 }

    static func load(from defaults: UserDefaults) -> Self {
        if let saved = defaults.string(forKey: "menuBarIconStyle"), let style = Self(rawValue: saved) { return style }
        // gkdl 1.0.0 stored four numeric choices, different from upstream gksdud.
        if let legacy = defaults.object(forKey: "iconStyle") as? Int {
            switch legacy {
            case 0: return .hanHi
            case 1: return .hanA
            case 2: return .languageCodes
            case 3: return .gkdl
            default: break
            }
        }
        return .gkdl
    }
    func save(to defaults: UserDefaults) { defaults.set(rawValue, forKey: "menuBarIconStyle") }
}
