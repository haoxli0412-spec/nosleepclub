import Foundation

func printStatus(_ message: String) {
    print("[\("nosleepclub".cyan)] \(message)")
}

func printError(_ message: String) {
    fputs("[\("nosleepclub".red)] \(message)\n", stderr)
}

extension String {
    var cyan: String { "\u{1B}[36m\(self)\u{1B}[0m" }
    var red: String { "\u{1B}[31m\(self)\u{1B}[0m" }
    var green: String { "\u{1B}[32m\(self)\u{1B}[0m" }
    var yellow: String { "\u{1B}[33m\(self)\u{1B}[0m" }
    var bold: String { "\u{1B}[1m\(self)\u{1B}[0m" }
}
