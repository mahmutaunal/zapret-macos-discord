import SwiftUI
import ZapretMenuCore

struct ZapretMenuView: View {
    @ObservedObject var model: ZapretMenuModel

    var body: some View {
        VStack(spacing: 16) {
            header
            statusCard
            primaryAction
            utilityActions
            Divider()
            launchAtLoginToggle
            Divider()
            footerActions
        }
        .padding(18)
        .frame(width: 340)
        .onAppear { model.refresh() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZMarkBadge(size: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("Zapret")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Text(L10n.text("app.subtitle", fallback: "Discord · macOS"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if model.isBusy {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var statusCard: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.16))
                    .frame(width: 40, height: 40)
                Circle()
                    .fill(statusColor)
                    .frame(width: 13, height: 13)
                    .shadow(color: statusColor.opacity(0.65), radius: 5)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(model.statusTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(model.statusDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(statusColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(statusColor.opacity(0.25), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var primaryAction: some View {
        if model.isRunning {
            Button {
                model.perform(.stop)
            } label: {
                Label(L10n.text("action.stop", fallback: "Stop Zapret"), systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ModernPrimaryButtonStyle(tint: .red))
            .disabled(model.isBusy)
        } else {
            Button {
                model.perform(.start)
            } label: {
                Label(L10n.text("action.start", fallback: "Start Zapret"), systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ModernPrimaryButtonStyle(tint: .indigo))
            .disabled(!model.isInstalled || model.isBusy)
        }
    }

    private var utilityActions: some View {
        HStack(spacing: 10) {
            Button {
                model.perform(.restart)
            } label: {
                Label(L10n.text("action.restart", fallback: "Restart"), systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .disabled(!model.isInstalled || model.isBusy)

            Button {
                model.refresh()
            } label: {
                Label(
                    L10n.text("action.refresh", fallback: "Refresh Status"),
                    systemImage: "arrow.triangle.2.circlepath"
                )
                .frame(maxWidth: .infinity)
            }
            .disabled(model.isBusy)
        }
        .buttonStyle(ModernSecondaryButtonStyle())
    }

    private var launchAtLoginToggle: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.text("login.title", fallback: "Open menu bar at login"))
                    .font(.callout.weight(.medium))
                Text(L10n.text("login.detail", fallback: "The Zapret service won't start automatically"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Toggle(
                "",
                isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .frame(maxWidth: .infinity)
    }

    private var footerActions: some View {
        HStack {
            Button(L10n.text("action.stopAndQuit", fallback: "Stop Service and Quit"), systemImage: "power") {
                model.stopAndQuit()
            }
            .disabled(!model.isInstalled || model.isBusy)

            Spacer()

            Button(L10n.text("action.quit", fallback: "Quit")) {
                model.quit()
            }
            .keyboardShortcut("q")
        }
        .buttonStyle(FooterButtonStyle())
        .font(.caption)
    }

    private var statusColor: Color {
        switch model.status {
        case .running:
            .green
        case .stopped:
            .orange
        case .needsRepair:
            .yellow
        case .checking:
            .blue
        case .notInstalled, .error:
            .red
        }
    }
}

private struct ModernPrimaryButtonStyle: ButtonStyle {
    let tint: Color

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .background(
                LinearGradient(
                    colors: [tint, tint.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: tint.opacity(configuration.isPressed ? 0.12 : 0.25), radius: 7, y: 3)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ModernSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
            .background(
                Color.primary.opacity(configuration.isPressed ? 0.10 : 0.055),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color.primary.opacity(0.09), lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.42)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct FooterButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? .primary : .secondary)
            .padding(.vertical, 5)
            .padding(.horizontal, 7)
            .background(
                Color.primary.opacity(configuration.isPressed ? 0.08 : 0),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .opacity(isEnabled ? 1 : 0.4)
    }
}

struct ZMarkBadge: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.33, green: 0.24, blue: 0.96),
                                 Color(red: 0.08, green: 0.65, blue: 0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            ZMark()
                .fill(.white)
                .padding(size * 0.22)
        }
        .frame(width: size, height: size)
        .shadow(color: .indigo.opacity(0.22), radius: 7, y: 3)
    }
}

struct ZMark: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height

        var path = Path()
        path.move(to: CGPoint(x: x + w * 0.08, y: y + h * 0.10))
        path.addLine(to: CGPoint(x: x + w * 0.92, y: y + h * 0.10))
        path.addLine(to: CGPoint(x: x + w * 0.92, y: y + h * 0.28))
        path.addLine(to: CGPoint(x: x + w * 0.34, y: y + h * 0.75))
        path.addLine(to: CGPoint(x: x + w * 0.92, y: y + h * 0.75))
        path.addLine(to: CGPoint(x: x + w * 0.92, y: y + h * 0.92))
        path.addLine(to: CGPoint(x: x + w * 0.08, y: y + h * 0.92))
        path.addLine(to: CGPoint(x: x + w * 0.08, y: y + h * 0.74))
        path.addLine(to: CGPoint(x: x + w * 0.66, y: y + h * 0.27))
        path.addLine(to: CGPoint(x: x + w * 0.08, y: y + h * 0.27))
        path.closeSubpath()
        return path
    }
}
