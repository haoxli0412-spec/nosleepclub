import Foundation

final class CaffeinateProcess {
    private var process: Process?

    func start() -> Bool {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        proc.arguments = ["-d", "-i", "-s"]

        do {
            try proc.run()
            process = proc
            return true
        } catch {
            printError("Failed to start caffeinate: \(error.localizedDescription)")
            return false
        }
    }

    func stop() {
        process?.terminate()
        process?.waitUntilExit()
        process = nil
    }

    deinit {
        stop()
    }
}
