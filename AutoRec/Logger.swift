import Foundation
import os

private let logger = os.Logger(subsystem: "com.local.autorec", category: "main")

/// Log to both os_log and a file for debugging
func log(_ message: String) {
    logger.info("\(message, privacy: .public)")
    // Also append to a log file
    let logPath = NSString("~/Downloads/AutoRec/autorec.log").expandingTildeInPath
    let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logPath) {
            if let handle = FileHandle(forWritingAtPath: logPath) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            FileManager.default.createFile(atPath: logPath, contents: data)
        }
    }
}
