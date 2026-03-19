# AutoRec

A lightweight macOS menu bar app that automatically records your calls — system audio, microphone, and optionally screen — with local transcription support.

## Features

- **Auto-detection** — monitors microphone usage and starts recording when a call begins (Zoom, Teams, FaceTime, etc.)
- **System audio capture** — records what you hear via ScreenCaptureKit
- **Microphone capture** — records your voice into a separate track
- **Screen recording** — optional screen capture at 10 fps (toggleable)
- **Auto-transcription** — runs [whisper.cpp](https://github.com/ggerganov/whisper.cpp) locally after each call (no data leaves your machine)
- **Menu bar only** — lives in the status bar, no dock icon

## Requirements

- macOS 13+
- Xcode Command Line Tools (for building)
- [whisper-cli](https://github.com/ggerganov/whisper.cpp) + [ffmpeg](https://ffmpeg.org/) (optional, for transcription)

## Build & Install

```bash
git clone https://github.com/huopolinen/AutoRec.git
cd AutoRec
bash build-app.sh
cp -r AutoRec.app /Applications/
```

On first launch macOS will ask for **Microphone** and **Screen Recording** permissions.

## Usage

Click the menu bar icon to:

- **Start/Stop Recording** manually
- **Pause/Resume** an active recording
- **Auto-detect Calls** — toggle automatic recording when a call is detected
- **Record Screen** — toggle screen capture
- **Auto-transcribe** — toggle post-call transcription via whisper.cpp

Recordings are saved to `~/Downloads/AutoRec/` by default. Each session produces:

| File | Contents |
|------|----------|
| `call_<timestamp>_system.m4a` | System audio (what you hear) |
| `call_<timestamp>_mic.m4a` | Microphone (your voice) |
| `call_<timestamp>_screen.mp4` | Screen recording (if enabled) |
| `call_<timestamp>_*.txt` | Transcription (if enabled) |

## Transcription Setup

Install whisper.cpp and ffmpeg:

```bash
brew install ffmpeg
# Build whisper.cpp from source or install via Homebrew
brew install whisper-cpp
```

AutoRec will auto-detect `whisper-cli` in your PATH.

## License

MIT
