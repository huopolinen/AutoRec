# AutoRec

A lightweight macOS menu bar app that automatically records your calls — system audio, microphone, and optionally screen — with local transcription support. Everything stays on your machine.

## Features

- **Auto-detection** — monitors microphone usage and starts recording when a call begins (Zoom, Teams, FaceTime, etc.)
- **System audio capture** — records what you hear via ScreenCaptureKit (HE-AAC, 48kHz stereo)
- **Microphone capture** — records your voice into a separate track (HE-AAC v2, 48kHz mono)
- **Screen recording** — optional screen capture at 10 fps, H.264 (toggleable)
- **Auto-transcription** — runs [whisper.cpp](https://github.com/ggerganov/whisper.cpp) locally after each call (no data leaves your machine)
- **Menu bar indicator** — gray circle when idle, red when recording, orange when paused

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
- **Output folder** — choose where recordings are saved

Recordings are saved to `~/Downloads/AutoRec/` by default. Each session produces:

| File | Contents |
|------|----------|
| `call_<timestamp>_system.m4a` | System audio (what you hear) |
| `call_<timestamp>_mic.m4a` | Microphone (your voice) |
| `call_<timestamp>_screen.mp4` | Screen recording (if enabled) |
| `call_<timestamp>_*.txt` | Transcription (if enabled) |

## Audio Quality

AutoRec uses efficient HE-AAC codecs to keep files small while maintaining clear speech for transcription:

| Track | Codec | Sample Rate | Bitrate | Notes |
|-------|-------|-------------|---------|-------|
| System audio | HE-AAC v1 | 48 kHz | 48 kbps stereo | SBR for high-frequency reconstruction |
| Microphone | HE-AAC v2 | 48 kHz | 32 kbps mono | Parametric Stereo + SBR, optimal for speech |

## Transcription Setup

Install whisper.cpp and ffmpeg:

```bash
brew install ffmpeg whisper-cpp
```

AutoRec will auto-detect `whisper-cli` in your PATH. A whisper model is required — download one:

```bash
# Base multilingual model (recommended, ~150MB, supports Russian and other languages)
curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin" -o /usr/local/share/whisper-cpp/ggml-base.bin
```

## License

MIT
