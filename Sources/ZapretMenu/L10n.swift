import Foundation

enum L10n {
    static func text(_ key: String, fallback: String) -> String {
        NSLocalizedString(key, bundle: .main, value: fallback, comment: "")
    }
}
