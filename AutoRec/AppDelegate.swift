import Cocoa
import CoreGraphics
import ScreenCaptureKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var recordingManager: RecordingManager!
    private var callDetector: CallDetector!
    private let settings = SettingsManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon — menu bar only
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()

        recordingManager = RecordingManager()
        recordingManager.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.updateStatusIcon(state)
            }
        }
        // Pause call detector while recording (our own mic usage would confuse it)
        recordingManager.onRecordingActiveChanged = { [weak self] active in
            if active {
                self?.callDetector.pause()
            } else {
                if self?.settings.autoDetect == true {
                    self?.callDetector.resume()
                }
            }
        }

        callDetector = CallDetector()
        callDetector.onCallStarted = { [weak self] in
            self?.recordingManager.startRecording()
        }
        callDetector.onCallEnded = { [weak self] in
            self?.recordingManager.stopRecording()
        }
        if settings.autoDetect {
            callDetector.startMonitoring()
        }

        // Request screen capture permission early via CoreGraphics
        // This uses the stable TCC flow instead of ScreenCaptureKit's picker
        if CGPreflightScreenCaptureAccess() {
            print("[AppDelegate] Screen capture permission already granted")
        } else {
            print("[AppDelegate] Requesting screen capture permission...")
            CGRequestScreenCaptureAccess()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.fill",
                                   accessibilityDescription: "AutoRec")
            button.contentTintColor = .systemGray
        }

        updateMenu()
    }

    private func updateMenu() {
        let menu = NSMenu()

        let state = recordingManager?.state ?? .idle
        let stateItem = NSMenuItem(title: stateLabel(state), action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        menu.addItem(stateItem)

        menu.addItem(NSMenuItem.separator())

        switch state {
        case .recording:
            let pauseItem = NSMenuItem(title: "Pause", action: #selector(pauseRecording), keyEquivalent: "")
            pauseItem.target = self
            menu.addItem(pauseItem)

            let stopItem = NSMenuItem(title: "Stop Recording", action: #selector(stopRecording), keyEquivalent: "")
            stopItem.target = self
            menu.addItem(stopItem)

        case .paused:
            let resumeItem = NSMenuItem(title: "Resume", action: #selector(resumeRecording), keyEquivalent: "")
            resumeItem.target = self
            menu.addItem(resumeItem)

            let stopItem = NSMenuItem(title: "Stop Recording", action: #selector(stopRecording), keyEquivalent: "")
            stopItem.target = self
            menu.addItem(stopItem)

        default:
            let startItem = NSMenuItem(title: "Start Recording", action: #selector(startRecording), keyEquivalent: "")
            startItem.target = self
            menu.addItem(startItem)
        }

        let autoItem = NSMenuItem(title: "Auto-detect Calls", action: #selector(toggleAutoDetect), keyEquivalent: "")
        autoItem.target = self
        autoItem.state = settings.autoDetect ? .on : .off
        menu.addItem(autoItem)

        let videoItem = NSMenuItem(title: "Record Screen", action: #selector(toggleRecordScreen), keyEquivalent: "")
        videoItem.target = self
        videoItem.state = settings.recordScreen ? .on : .off
        menu.addItem(videoItem)

        let transcribeItem = NSMenuItem(title: "Auto-transcribe (Whisper)", action: #selector(toggleAutoTranscribe), keyEquivalent: "")
        transcribeItem.target = self
        if Transcriber.shared.isAvailable {
            transcribeItem.state = settings.autoTranscribe ? .on : .off
        } else {
            transcribeItem.state = .off
            transcribeItem.isEnabled = false
            transcribeItem.title = "Auto-transcribe (whisper-cpp not found)"
        }
        menu.addItem(transcribeItem)

        menu.addItem(NSMenuItem.separator())

        let folderItem = NSMenuItem(title: "Output: \(settings.outputPath)", action: #selector(chooseFolder), keyEquivalent: "")
        folderItem.target = self
        menu.addItem(folderItem)

        let openItem = NSMenuItem(title: "Open Recordings Folder", action: #selector(openFolder), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func stateLabel(_ state: RecordingState) -> String {
        if recordingManager?.isTranscribing == true && state == .idle {
            return "📝 Transcribing..."
        }
        switch state {
        case .idle: return "⏹ Not Recording"
        case .recording: return "🔴 Recording..."
        case .paused: return "⏸ Paused"
        case .starting: return "⏳ Starting..."
        case .stopping: return "⏳ Stopping..."
        }
    }

    private func updateStatusIcon(_ state: RecordingState) {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.fill",
                                   accessibilityDescription: "AutoRec")
            switch state {
            case .recording:
                button.contentTintColor = .systemRed
            case .paused:
                button.contentTintColor = .systemOrange
            case .starting, .stopping:
                button.contentTintColor = .systemYellow
            case .idle:
                button.contentTintColor = .systemGray
            }
        }
        updateMenu()
    }

    @objc private func startRecording() {
        recordingManager.startRecording()
    }

    @objc private func pauseRecording() {
        recordingManager.pauseRecording()
    }

    @objc private func resumeRecording() {
        recordingManager.resumeRecording()
    }

    @objc private func stopRecording() {
        recordingManager.stopRecording()
    }

    @objc private func toggleAutoDetect() {
        settings.autoDetect.toggle()
        if settings.autoDetect {
            callDetector.startMonitoring()
        } else {
            callDetector.stopMonitoring()
        }
        updateMenu()
    }

    @objc private func toggleRecordScreen() {
        settings.recordScreen.toggle()
        updateMenu()
    }

    @objc private func toggleAutoTranscribe() {
        settings.autoTranscribe.toggle()
        updateMenu()
    }

    @objc private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        panel.message = "Choose folder for recordings"

        if panel.runModal() == .OK, let url = panel.url {
            settings.outputPath = url.path
            updateMenu()
        }
    }

    @objc private func openFolder() {
        let url = URL(fileURLWithPath: settings.outputPath)
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        recordingManager.stopRecording()
        NSApp.terminate(nil)
    }
}
