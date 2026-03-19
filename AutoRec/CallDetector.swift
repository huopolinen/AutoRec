import Foundation
import CoreAudio
import AVFoundation

/// Detects active calls by monitoring microphone usage.
/// When the mic is grabbed by another process (Zoom, Teams, FaceTime, etc.)
/// we treat that as a call in progress.
class CallDetector {
    var onCallStarted: (() -> Void)?
    var onCallEnded: (() -> Void)?

    private var timer: Timer?
    private var micInUse = false
    private var paused = false
    private let pollInterval: TimeInterval = 2.0

    /// How many consecutive polls must agree before we change state.
    /// Prevents flicker from brief mic grabs/releases.
    private let debounceCount = 2
    private var activeCount = 0
    private var inactiveCount = 0

    func startMonitoring() {
        stopMonitoring()
        paused = false
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkMicStatus()
        }
        timer?.tolerance = 0.5
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    /// Pause detection (e.g. while we are recording and using the mic ourselves)
    func pause() {
        paused = true
    }

    /// Resume detection
    func resume() {
        paused = false
        // Reset debounce counters so we don't immediately trigger
        activeCount = 0
        inactiveCount = 0
        micInUse = false
    }

    private func checkMicStatus() {
        guard !paused else { return }

        let inUse = isMicrophoneInUseByOtherProcess()

        if inUse {
            activeCount += 1
            inactiveCount = 0
        } else {
            inactiveCount += 1
            activeCount = 0
        }

        if activeCount >= debounceCount && !micInUse {
            micInUse = true
            print("[CallDetector] Microphone active for \(debounceCount) polls — call detected")
            onCallStarted?()
        } else if inactiveCount >= debounceCount && micInUse {
            micInUse = false
            print("[CallDetector] Microphone inactive for \(debounceCount) polls — call ended")
            onCallEnded?()
        }
    }

    /// Check if the default input device is being used by querying its "is running" property.
    private func isMicrophoneInUseByOtherProcess() -> Bool {
        var defaultDeviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &defaultDeviceID
        )
        guard status == noErr, defaultDeviceID != kAudioObjectUnknown else {
            return false
        }

        var isRunning: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        var runningAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let runStatus = AudioObjectGetPropertyData(
            defaultDeviceID, &runningAddress, 0, nil, &size, &isRunning
        )
        guard runStatus == noErr else { return false }

        return isRunning != 0
    }
}
