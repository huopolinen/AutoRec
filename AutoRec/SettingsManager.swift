import Foundation

class SettingsManager {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let outputPath = "outputPath"
        static let autoDetect = "autoDetect"
        static let recordScreen = "recordScreen"
        static let autoTranscribe = "autoTranscribe"
    }

    var outputPath: String {
        get {
            defaults.string(forKey: Keys.outputPath)
                ?? NSString("~/Downloads/AutoRec").expandingTildeInPath
        }
        set { defaults.set(newValue, forKey: Keys.outputPath) }
    }

    var autoDetect: Bool {
        get {
            if defaults.object(forKey: Keys.autoDetect) == nil { return true }
            return defaults.bool(forKey: Keys.autoDetect)
        }
        set { defaults.set(newValue, forKey: Keys.autoDetect) }
    }

    var recordScreen: Bool {
        get {
            if defaults.object(forKey: Keys.recordScreen) == nil { return true }
            return defaults.bool(forKey: Keys.recordScreen)
        }
        set { defaults.set(newValue, forKey: Keys.recordScreen) }
    }

    var autoTranscribe: Bool {
        get {
            if defaults.object(forKey: Keys.autoTranscribe) == nil { return true }
            return defaults.bool(forKey: Keys.autoTranscribe)
        }
        set { defaults.set(newValue, forKey: Keys.autoTranscribe) }
    }

    /// Ensure output directory exists
    func ensureOutputDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: outputPath) {
            try? fm.createDirectory(atPath: outputPath, withIntermediateDirectories: true)
        }
    }
}
