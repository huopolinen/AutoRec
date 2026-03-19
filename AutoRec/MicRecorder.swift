import Foundation
import AVFoundation

/// Records microphone audio (what you say) into a separate .m4a file
/// using AVAudioEngine + AVAudioFile — simple and reliable.
class MicRecorder {
    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var isRecording = false
    var isPaused = false
    private let outputURL: URL

    init(outputURL: URL) {
        self.outputURL = outputURL
    }

    func start() throws {
        guard !isRecording else { return }

        // Remove existing file
        try? FileManager.default.removeItem(at: outputURL)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw MicRecorderError.noMicAvailable
        }

        // HE-AAC v2 — optimized for mono speech, clear at low bitrates
        let audioFile = try AVAudioFile(
            forWriting: outputURL,
            settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC_HE_V2,
                AVSampleRateKey: 48000,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 32000,
            ]
        )

        self.audioFile = audioFile

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, self.isRecording, !self.isPaused else { return }
            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                print("[MicRecorder] Write error: \(error)")
            }
        }

        try engine.start()
        self.engine = engine
        isRecording = true

        print("[MicRecorder] Recording started → \(outputURL.lastPathComponent)")
    }

    func stop() {
        guard isRecording else { return }
        isRecording = false

        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        audioFile = nil

        print("[MicRecorder] Recording stopped")
    }
}

enum MicRecorderError: Error, LocalizedError {
    case noMicAvailable

    var errorDescription: String? {
        switch self {
        case .noMicAvailable: return "No microphone available or format invalid"
        }
    }
}
