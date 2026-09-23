import Foundation
import ZapretMenuCore

enum PrivilegedCommandError: LocalizedError {
    case cancelled
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            L10n.text("error.cancelled", fallback: "The operation was cancelled")
        case .executionFailed(let message):
            message.isEmpty
                ? L10n.text("error.command", fallback: "The Zapret command could not be run")
                : message
        }
    }
}

enum PrivilegedCommandRunner {
    static func run(_ action: ZapretAction) async throws {
        try await Task.detached(priority: .userInitiated) {
            var errorInfo: NSDictionary?
            guard let script = NSAppleScript(source: action.appleScriptSource) else {
                throw PrivilegedCommandError.executionFailed(
                    L10n.text("error.authorization", fallback: "The authorization command could not be prepared")
                )
            }

            script.executeAndReturnError(&errorInfo)

            guard let errorInfo else { return }
            let errorNumber = errorInfo[NSAppleScript.errorNumber] as? Int
            if errorNumber == -128 {
                throw PrivilegedCommandError.cancelled
            }

            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? ""
            throw PrivilegedCommandError.executionFailed(message)
        }.value
    }
}
