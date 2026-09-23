import Foundation
import Testing
@testable import ZapretMenuCore

@Suite("Zapret service")
struct ZapretServiceTests {
    @Test("Only fixed service commands are generated")
    func fixedCommands() {
        #expect(ZapretAction.start.privilegedShellCommand.contains("ACTION=start"))
        #expect(ZapretAction.stop.privilegedShellCommand.contains("ACTION=stop"))
        #expect(ZapretAction.restart.privilegedShellCommand.contains("ACTION=restart"))
        #expect(ZapretAction.start.privilegedShellCommand.contains("SERVICE=/opt/zapret/init.d/macos/zapret"))
    }

    @Test("AppleScript asks for standard administrator authorization")
    func administratorAuthorization() {
        #expect(ZapretAction.start.appleScriptSource.hasPrefix("do shell script \"/bin/sh -c"))
        #expect(ZapretAction.start.appleScriptSource.hasSuffix("with administrator privileges"))
    }

    @Test("Every privileged control script has valid shell syntax", arguments: ZapretAction.allCases)
    func shellSyntax(action: ZapretAction) throws {
        let process = Process()
        let input = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-n"]
        process.standardInput = input
        process.standardError = Pipe()

        try process.run()
        input.fileHandleForWriting.write(Data(ZapretAction.controlScript(action: action.rawValue).utf8))
        try input.fileHandleForWriting.close()
        process.waitUntilExit()

        #expect(process.terminationStatus == 0)
    }

    @Test("Missing service is reported as not installed")
    func missingService() {
        let reader = ZapretStatusReader(
            servicePath: "/path/that/does/not/exist",
            runningProcessID: { nil }
        )
        #expect(reader.read() == .notInstalled)
    }

    @Test("A discovered Zapret worker is reported as running")
    func runningService() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let service = directory.appendingPathComponent("zapret")
        let pidFile = directory.appendingPathComponent("tpws1.pid")
        try Data("#!/bin/sh\n".utf8).write(to: service)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: service.path)
        try Data("4242\n".utf8).write(to: pidFile)

        let reader = ZapretStatusReader(
            servicePath: service.path,
            pidFilePath: pidFile.path,
            runningProcessID: { 4242 }
        )
        #expect(reader.read() == .running(pid: 4242))
    }

    @Test("No Zapret worker is reported as stopped")
    func stoppedService() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let service = directory.appendingPathComponent("zapret")
        try Data("#!/bin/sh\n".utf8).write(to: service)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: service.path)

        let reader = ZapretStatusReader(
            servicePath: service.path,
            runningProcessID: { nil }
        )
        #expect(reader.read() == .stopped)
    }

    @Test("A worker without a matching pidfile needs repair")
    func missingPidFileNeedsRepair() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let service = directory.appendingPathComponent("zapret")
        try Data("#!/bin/sh\n".utf8).write(to: service)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: service.path)

        let reader = ZapretStatusReader(
            servicePath: service.path,
            pidFilePath: directory.appendingPathComponent("missing.pid").path,
            runningProcessID: { 4242 }
        )
        #expect(reader.read() == .needsRepair(pid: 4242))
    }

    @Test("Only genuine Zapret worker paths are accepted")
    func workerPathValidation() {
        #expect(ZapretStatusReader.isZapretWorkerExecutable(at: "/opt/zapret/binaries/my/tpws"))
        #expect(ZapretStatusReader.isZapretWorkerExecutable(at: "/opt/zapret/nfq/nfqws"))
        #expect(!ZapretStatusReader.isZapretWorkerExecutable(at: "/Applications/Zapret Menu.app/Contents/MacOS/ZapretMenu"))
        #expect(!ZapretStatusReader.isZapretWorkerExecutable(at: "/tmp/tpws"))
    }
}
