import Foundation
import ArasoCore

/// Only the current marked word lives here. No document access, learning or persistence.
struct BetaComposition {
    static let limit = 128
    private(set) var keys = ""
    private(set) var forced: Language?
    private let engine: any DecisionEngine

    init(engine: any DecisionEngine) { self.engine = engine }

    var decision: Decision { engine.decide(keys, context: DecisionContext(japanese: false)) }
    var text: String {
        guard !keys.isEmpty else { return "" }
        guard let forced else { return decision.output }
        if forced == .mixed { return decision.language == .mixed ? decision.output : keys }
        return engine.render(keys, as: forced)
    }
    mutating func append(_ character: Character) -> Bool {
        guard keys.count < Self.limit, character.isASCII, character.isLetter else { return false }
        keys.append(character)
        return true
    }
    mutating func delete() { if !keys.isEmpty { keys.removeLast() }; if keys.isEmpty { forced = nil } }
    mutating func cycle() {
        guard !keys.isEmpty else { return }
        forced = (forced ?? decision.language).next(for: keys, splits: decision.language == .mixed)
    }
    mutating func clear() { keys = ""; forced = nil }
}
