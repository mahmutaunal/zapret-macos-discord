import Darwin
import Foundation

public enum ZapretAction: String, CaseIterable, Sendable {
    case start
    case stop
    case restart

    public static let servicePath = "/opt/zapret/init.d/macos/zapret"

    /// The command is intentionally not configurable. The app can only call the
    /// three actions supported by Zapret's own macOS service script.
    public var privilegedShellCommand: String {
        let script = Self.controlScript(action: rawValue)
        let quotedScript = "'" + script.replacingOccurrences(of: "'", with: "'\\''") + "'"
        return "/bin/sh -c \(quotedScript)"
    }

    public var appleScriptSource: String {
        let escaped = privilegedShellCommand
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "do shell script \"\(escaped)\" with administrator privileges"
    }

    static func controlScript(action: String) -> String {
        """
        set -eu
        SERVICE=/opt/zapret/init.d/macos/zapret
        ACTION=\(action)

        worker_pids() {
          /usr/bin/pgrep -f '^/opt/zapret/(tpws/tpws|nfq/nfqws|binaries/[^ ]+/(tpws|nfqws|dvtws))( |$)' || true
        }

        repair_single_pidfile() {
          PIDS="$(worker_pids)"
          set -- $PIDS
          [ "$#" -eq 1 ] || return 0
          PID="$1"
          NAME="$(/bin/ps -p "$PID" -o command= | /usr/bin/awk '{name=$1; sub(".*/", "", name); print name}')"
          case "$NAME" in tpws|nfqws|dvtws) ;; *) return 1 ;; esac
          /usr/bin/printf '%s\n' "$PID" > "/var/run/${NAME}1.pid"
          /usr/sbin/chown root:daemon "/var/run/${NAME}1.pid"
          /bin/chmod 0644 "/var/run/${NAME}1.pid"
        }

        stop_workers() {
          PIDS="$(worker_pids)"
          [ -z "$PIDS" ] || /bin/kill -TERM $PIDS
          I=0
          while [ -n "$(worker_pids)" ] && [ "$I" -lt 20 ]; do
            /bin/sleep 0.1
            I=$((I + 1))
          done
          PIDS="$(worker_pids)"
          [ -z "$PIDS" ] || /bin/kill -KILL $PIDS
          /bin/rm -f /var/run/tpws[0-9]*.pid /var/run/nfqws[0-9]*.pid /var/run/dvtws[0-9]*.pid
          [ -z "$(worker_pids)" ] || { echo 'Zapret worker could not be stopped.' >&2; exit 1; }
        }

        stop_service() {
          repair_single_pidfile
          "$SERVICE" stop
          stop_workers
        }

        start_service() {
          PIDS="$(worker_pids)"
          set -- $PIDS
          if [ "$#" -gt 1 ]; then
            stop_workers
          else
            repair_single_pidfile
          fi
          "$SERVICE" start
          I=0
          while [ -z "$(worker_pids)" ] && [ "$I" -lt 50 ]; do
            /bin/sleep 0.1
            I=$((I + 1))
          done
          [ -n "$(worker_pids)" ] || { echo 'Zapret worker did not start.' >&2; exit 1; }
        }

        case "$ACTION" in
          start) start_service ;;
          stop) stop_service ;;
          restart) stop_service; start_service ;;
          *) exit 64 ;;
        esac
        """
    }
}

public enum ZapretServiceStatus: Equatable, Sendable {
    case notInstalled
    case stopped
    case needsRepair(pid: Int32)
    case running(pid: Int32)
}

public struct ZapretStatusReader {
    public static let pidFilePath = "/var/run/tpws1.pid"

    private let servicePath: String
    private let pidFilePath: String
    private let fileManager: FileManager
    private let runningProcessID: () -> Int32?

    public init(
        servicePath: String = ZapretAction.servicePath,
        pidFilePath: String = Self.pidFilePath,
        fileManager: FileManager = .default,
        runningProcessID: @escaping () -> Int32? = Self.defaultRunningProcessID
    ) {
        self.servicePath = servicePath
        self.pidFilePath = pidFilePath
        self.fileManager = fileManager
        self.runningProcessID = runningProcessID
    }

    public func read() -> ZapretServiceStatus {
        guard fileManager.isExecutableFile(atPath: servicePath) else {
            return .notInstalled
        }

        guard let workerPID = runningProcessID() else {
            return .stopped
        }

        guard
            let contents = try? String(contentsOfFile: pidFilePath, encoding: .utf8),
            let recordedPID = Int32(contents.trimmingCharacters(in: .whitespacesAndNewlines)),
            recordedPID == workerPID
        else {
            return .needsRepair(pid: workerPID)
        }

        return .running(pid: workerPID)
    }

    /// Zapret's pidfile can briefly disappear or become stale after rapid
    /// stop/start cycles. Inspecting the executable path avoids both that race
    /// and false positives caused when macOS reuses a stale PID.
    public static func defaultRunningProcessID() -> Int32? {
        let capacity = max(Int(proc_listallpids(nil, 0)) + 64, 128)
        var processIDs = [pid_t](repeating: 0, count: capacity)
        let byteCount = Int32(processIDs.count * MemoryLayout<pid_t>.stride)
        let processCount = Int(proc_listallpids(&processIDs, byteCount))

        guard processCount > 0 else { return nil }

        for pid in processIDs.prefix(min(processCount, processIDs.count)) where pid > 0 {
            var pathBuffer = [CChar](repeating: 0, count: 4096)
            guard proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count)) > 0 else {
                continue
            }

            let pathBytes = pathBuffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
            let executablePath = String(decoding: pathBytes, as: UTF8.self)
            if isZapretWorkerExecutable(at: executablePath) {
                return pid
            }
        }

        return nil
    }

    static func isZapretWorkerExecutable(at path: String) -> Bool {
        let executableName = URL(fileURLWithPath: path).lastPathComponent
        return path.hasPrefix("/opt/zapret/")
            && ["tpws", "nfqws", "dvtws"].contains(executableName)
    }
}
