import Foundation

enum AppIdentity {
    static let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "gkdl"
    static let isDevelopment = Bundle.main.bundleIdentifier?.hasPrefix("kr.twentyoz.gkdl.dev") == true
}
