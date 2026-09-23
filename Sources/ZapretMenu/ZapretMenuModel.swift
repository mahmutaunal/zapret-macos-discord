import AppKit
import Foundation
import ServiceManagement
import ZapretMenuCore

@MainActor
final class ZapretMenuModel: ObservableObject {
    enum DisplayStatus: Equatable {
        case checking
        case notInstalled
        case stopped
        case needsRepair
        case running
        case error(String)
    }

    @Published private(set) var status: DisplayStatus = .checking
    @Published private(set) var isBusy = false
    @Published private(set) var launchAtLogin = false

    private let statusReader = ZapretStatusReader()

    init() {
        refresh()
        refreshLaunchAtLogin()
        startMonitoring()
    }

    var statusTitle: String {
        switch status {
        case .checking:
            L10n.text("status.checking.title", fallback: "Checking status…")
        case .notInstalled:
            L10n.text("status.notInstalled.title", fallback: "Zapret is not installed")
        case .stopped:
            L10n.text("status.stopped.title", fallback: "Zapret is off")
        case .needsRepair:
            L10n.text("status.needsRepair.title", fallback: "Zapret needs repair")
        case .running:
            L10n.text("status.running.title", fallback: "Zapret is running")
        case .error(let message):
            message
        }
    }

    var statusSymbol: String {
        switch status {
        case .checking:
            "clock"
        case .notInstalled:
            "exclamationmark.triangle"
        case .stopped:
            "circle"
        case .needsRepair:
            "wrench.and.screwdriver.fill"
        case .running:
            "checkmark.circle.fill"
        case .error:
            "xmark.octagon.fill"
        }
    }

    var statusDetail: String {
        switch status {
        case .checking:
            L10n.text("status.checking.detail", fallback: "Checking the service status")
        case .notInstalled:
            L10n.text("status.notInstalled.detail", fallback: "Install Zapret with install.sh first")
        case .stopped:
            L10n.text("status.stopped.detail", fallback: "Discord routing is currently disabled")
        case .needsRepair:
            L10n.text("status.needsRepair.detail", fallback: "Start Zapret to repair its worker state")
        case .running:
            L10n.text("status.running.detail", fallback: "Network routing for Discord is active")
        case .error:
            L10n.text("status.error.detail", fallback: "Try the action again for details")
        }
    }

    var isInstalled: Bool {
        if case .notInstalled = status { return false }
        return true
    }

    var isRunning: Bool {
        if case .running = status { return true }
        return false
    }

    func refresh() {
        guard !isBusy else { return }
        apply(statusReader.read())
    }

    func perform(_ action: ZapretAction) {
        guard !isBusy else { return }
        isBusy = true
        status = .checking

        Task {
            do {
                try await PrivilegedCommandRunner.run(action)
                await refreshUntilSettled(for: action)
            } catch PrivilegedCommandError.cancelled {
                apply(statusReader.read())
            } catch {
                status = .error(error.localizedDescription)
            }
            isBusy = false
        }
    }

    func stopAndQuit() {
        guard !isBusy else { return }

        if case .stopped = status {
            NSApp.terminate(nil)
            return
        }
        if case .notInstalled = status {
            NSApp.terminate(nil)
            return
        }

        isBusy = true
        status = .checking
        Task {
            do {
                try await PrivilegedCommandRunner.run(.stop)
                NSApp.terminate(nil)
            } catch PrivilegedCommandError.cancelled {
                apply(statusReader.read())
                isBusy = false
            } catch {
                status = .error(error.localizedDescription)
                isBusy = false
            }
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            status = .error(L10n.text("error.loginItem", fallback: "The login setting could not be changed"))
        }
        refreshLaunchAtLogin()
    }

    func quit() {
        NSApp.terminate(nil)
    }

    private func refreshLaunchAtLogin() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func startMonitoring() {
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard let self else { return }
                self.refresh()
            }
        }
    }

    private func refreshUntilSettled(for action: ZapretAction) async {
        var latest = statusReader.read()

        for attempt in 0..<20 {
            latest = statusReader.read()
            let reachedExpectedState: Bool
            switch (action, latest) {
            case (.stop, .stopped), (.start, .running), (.restart, .running):
                reachedExpectedState = true
            default:
                reachedExpectedState = false
            }

            if reachedExpectedState {
                apply(latest)
                return
            }

            if attempt < 19 {
                try? await Task.sleep(for: .milliseconds(250))
            }
        }

        apply(latest)
    }

    private func apply(_ serviceStatus: ZapretServiceStatus) {
        switch serviceStatus {
        case .notInstalled:
            status = .notInstalled
        case .stopped:
            status = .stopped
        case .needsRepair:
            status = .needsRepair
        case .running:
            status = .running
        }
    }
}
