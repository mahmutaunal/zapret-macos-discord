import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = ZapretMenuModel()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var statusObservation: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: 20)
        statusItem = item

        if let button = item.button {
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.toolTip = "Zapret"
            button.target = self
            button.action = #selector(togglePopover)
        }

        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 340, height: 430)
        popover.contentViewController = NSHostingController(
            rootView: ZapretMenuView(model: model)
        )

        statusObservation = model.$status
            .sink { [weak self] status in
                self?.updateStatusIcon(for: status)
            }

    }

    func applicationWillTerminate(_ notification: Notification) {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            model.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateStatusIcon(for status: ZapretMenuModel.DisplayStatus) {
        statusItem?.button?.image = makeStatusImage(status: status)
        statusItem?.button?.setAccessibilityLabel(model.statusTitle)
    }

    private func makeStatusImage(status: ZapretMenuModel.DisplayStatus) -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { _ in
            let mark = NSBezierPath()
            mark.move(to: NSPoint(x: 1.5, y: 13.5))
            mark.line(to: NSPoint(x: 13, y: 13.5))
            mark.line(to: NSPoint(x: 13, y: 11))
            mark.line(to: NSPoint(x: 5.5, y: 4))
            mark.line(to: NSPoint(x: 13, y: 4))
            mark.line(to: NSPoint(x: 13, y: 1.5))
            mark.line(to: NSPoint(x: 1.5, y: 1.5))
            mark.line(to: NSPoint(x: 1.5, y: 4))
            mark.line(to: NSPoint(x: 9, y: 11))
            mark.line(to: NSPoint(x: 1.5, y: 11))
            mark.close()
            NSColor.labelColor.setFill()
            mark.fill()

            let color: NSColor = switch status {
            case .running: .systemGreen
            case .stopped: .systemOrange
            case .needsRepair: .systemYellow
            case .checking: .systemBlue
            case .notInstalled, .error: .systemRed
            }

            color.setFill()
            NSBezierPath(ovalIn: NSRect(x: 11.5, y: 0, width: 4.5, height: 4.5)).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
