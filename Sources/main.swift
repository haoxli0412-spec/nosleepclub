import Foundation
import Darwin

let version = "0.1.0"

func showHelp() {
    print("""
    \("nosleepclub".bold) v\(version) — keep your Mac awake with the lid closed

    \("USAGE:".yellow)
        nosleepclub [OPTIONS]

    \("OPTIONS:".yellow)
        -w, --width <N>      Virtual display width in pixels (default: 1920)
        -h, --height <N>     Virtual display height in pixels (default: 1080)
        --hidpi              Enable HiDPI (Retina) mode
        --version            Print version
        --help               Print this help

    \("HOW IT WORKS:".yellow)
        1. Creates a virtual display so macOS thinks an external monitor is connected
        2. Runs caffeinate -d -i -s to prevent display/idle/system sleep
        3. You can now close the lid — macOS enters clamshell mode instead of sleeping

    \("REQUIREMENTS:".yellow)
        - macOS 14 (Sonoma) or later
        - Power adapter connected (required for clamshell mode)

    Press Ctrl+C to stop and remove the virtual display.
    """)
}

func showVersion() {
    print("nosleepclub \(version)")
}

func parseArgs() -> (width: Int, height: Int, hiDPI: Bool) {
    var width = 1920
    var height = 1080
    var hiDPI = false
    let args = CommandLine.arguments

    var i = 1
    while i < args.count {
        switch args[i] {
        case "-w", "--width":
            i += 1
            if i < args.count, let v = Int(args[i]) { width = v }
        case "-h", "--height":
            i += 1
            if i < args.count, let v = Int(args[i]) { height = v }
        case "--hidpi":
            hiDPI = true
        case "--version":
            showVersion()
            exit(0)
        case "--help":
            showHelp()
            exit(0)
        default:
            printError("Unknown option: \(args[i])")
            showHelp()
            exit(1)
        }
        i += 1
    }
    return (width, height, hiDPI)
}

func killExisting() {
    let pipe = Pipe()
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    proc.arguments = ["-x", "nosleepclub"]
    proc.standardOutput = pipe
    try? proc.run()
    proc.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let myPid = ProcessInfo.processInfo.processIdentifier
    let pids = String(data: data, encoding: .utf8)?
        .split(separator: "\n")
        .compactMap { Int32($0.trimmingCharacters(in: .whitespaces)) }
        .filter { $0 != myPid } ?? []
    for pid in pids {
        kill(pid, SIGTERM)
    }
    if !pids.isEmpty {
        for _ in 0..<10 {
            usleep(500_000)
            let check = Process()
            check.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
            check.arguments = ["-x", "nosleepclub"]
            let p = Pipe()
            check.standardOutput = p
            try? check.run()
            check.waitUntilExit()
            let alive = String(data: p.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .split(separator: "\n")
                .compactMap { Int32($0.trimmingCharacters(in: .whitespaces)) }
                .filter { $0 != myPid } ?? []
            if alive.isEmpty { break }
            kill(alive[0], SIGKILL)
        }
        printStatus("Stopped previous nosleepclub process")
    }
}

func main() {
    let config = parseArgs()

    printStatus("nosleepclub v\(version)")
    killExisting()
    printStatus("Creating virtual display (\(config.width)x\(config.height)\(config.hiDPI ? " HiDPI" : ""))...")

    let virtualDisplay = VirtualDisplay()
    var created = false
    for attempt in 1...3 {
        if virtualDisplay.create(width: config.width, height: config.height, hiDPI: config.hiDPI) {
            created = true
            break
        }
        if attempt < 3 {
            printStatus("Retrying in 2s... (\(attempt)/3)")
            sleep(2)
        }
    }
    guard created else {
        printError("Failed to create virtual display. Make sure you're on macOS 14+.")
        exit(1)
    }

    if let displayID = virtualDisplay.displayID {
        printStatus("Virtual display created (ID: \(displayID)) ✓".green)
    } else {
        printStatus("Virtual display created ✓".green)
    }

    printStatus("Starting caffeinate (preventing display + idle + system sleep)...")
    let caffeinate = CaffeinateProcess()
    guard caffeinate.start() else {
        printError("Failed to start caffeinate")
        virtualDisplay.destroy()
        exit(1)
    }
    printStatus("caffeinate running ✓".green)

    printStatus("")
    printStatus("You can now close the lid. Your Mac will stay awake.".bold)
    printStatus("Make sure your power adapter is connected for clamshell mode.")
    printStatus("Press Ctrl+C to stop.")
    printStatus("")

    let sigSources = [SIGINT, SIGTERM].map { sig -> DispatchSourceSignal in
        signal(sig, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
        source.setEventHandler {
            printStatus("")
            printStatus("Shutting down...")
            caffeinate.stop()
            printStatus("caffeinate stopped")
            virtualDisplay.destroy()
            printStatus("Virtual display removed")
            printStatus("Goodbye from nosleepclub 🌙")
            exit(0)
        }
        source.resume()
        return source
    }

    _ = sigSources
    dispatchMain()
}

main()
