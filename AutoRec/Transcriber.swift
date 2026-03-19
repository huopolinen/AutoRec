import Foundation

/// Transcribes audio files using whisper-cli (whisper.cpp).
/// Converts m4a → wav via ffmpeg, then runs whisper-cli.
class Transcriber {
    static let shared = Transcriber()

    private let whisperPath = "/usr/local/bin/whisper-cli"
    private let ffmpegPath: String = {
        // Try common paths
        for path in ["/opt/local/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/opt/homebrew/bin/ffmpeg"] {
            if FileManager.default.fileExists(atPath: path) { return path }
        }
        return "ffmpeg"
    }()
    private let modelPath = NSString("~/.local/share/whisper-models/ggml-base.bin").expandingTildeInPath

    var isAvailable: Bool {
        FileManager.default.fileExists(atPath: whisperPath) &&
        FileManager.default.fileExists(atPath: modelPath)
    }

    /// Transcribe an audio file. Returns the path to the transcript .txt file, or nil on failure.
    func transcribe(audioURL: URL, completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .utility).async { [self] in
            guard isAvailable else {
                print("[Transcriber] whisper-cli or model not found")
                completion(nil)
                return
            }

            let baseName = audioURL.deletingPathExtension().lastPathComponent
            let dir = audioURL.deletingLastPathComponent()
            let wavURL = dir.appendingPathComponent(baseName + ".wav")
            let transcriptBase = dir.appendingPathComponent(
                baseName.replacingOccurrences(of: "_mic", with: "_transcript")
                        .replacingOccurrences(of: "_system", with: "_transcript")
            )

            // Skip if transcript already exists
            let txtPath = transcriptBase.appendingPathExtension("txt")
            if FileManager.default.fileExists(atPath: txtPath.path) {
                print("[Transcriber] Transcript already exists: \(txtPath.lastPathComponent)")
                completion(txtPath)
                return
            }

            // Step 1: Convert m4a → wav (16kHz mono, required by whisper)
            print("[Transcriber] Converting to WAV: \(audioURL.lastPathComponent)")
            let convertResult = runProcess(
                ffmpegPath,
                args: ["-y", "-i", audioURL.path, "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", wavURL.path]
            )
            guard convertResult.exitCode == 0 else {
                print("[Transcriber] ffmpeg failed: \(convertResult.stderr)")
                completion(nil)
                return
            }

            // Step 2: Run whisper-cli
            print("[Transcriber] Transcribing: \(wavURL.lastPathComponent)")
            let whisperResult = runProcess(
                whisperPath,
                args: [
                    "-m", modelPath,
                    "-l", "auto",       // auto-detect language
                    "-otxt",            // output .txt
                    "-of", transcriptBase.path,  // output file base name
                    wavURL.path
                ]
            )

            // Clean up temp wav
            try? FileManager.default.removeItem(at: wavURL)

            if whisperResult.exitCode == 0 && FileManager.default.fileExists(atPath: txtPath.path) {
                print("[Transcriber] ✅ Transcript saved: \(txtPath.lastPathComponent)")
                completion(txtPath)
            } else {
                print("[Transcriber] ❌ Whisper failed: \(whisperResult.stderr)")
                completion(nil)
            }
        }
    }

    /// Transcribe all audio files for a recording session (mic + system).
    func transcribeSession(micURL: URL?, systemURL: URL?, completion: @escaping () -> Void) {
        let group = DispatchGroup()

        if let mic = micURL, FileManager.default.fileExists(atPath: mic.path) {
            // Only transcribe if file has content
            let attrs = try? FileManager.default.attributesOfItem(atPath: mic.path)
            let size = attrs?[.size] as? UInt64 ?? 0
            if size > 1000 {
                group.enter()
                transcribe(audioURL: mic) { _ in group.leave() }
            }
        }

        // System audio usually has the other side of the call
        if let sys = systemURL, FileManager.default.fileExists(atPath: sys.path) {
            let attrs = try? FileManager.default.attributesOfItem(atPath: sys.path)
            let size = attrs?[.size] as? UInt64 ?? 0
            if size > 1000 {
                group.enter()
                transcribe(audioURL: sys) { _ in group.leave() }
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    private struct ProcessResult {
        let exitCode: Int32
        let stdout: String
        let stderr: String
    }

    private func runProcess(_ path: String, args: [String]) -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ProcessResult(exitCode: -1, stdout: "", stderr: error.localizedDescription)
        }

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return ProcessResult(exitCode: process.terminationStatus, stdout: stdout, stderr: stderr)
    }
}
