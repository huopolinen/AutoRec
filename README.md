<img width="1408" height="768" alt="image" src="https://github.com/user-attachments/assets/95171c46-2717-4b21-91ad-2ae2d5622964" />

# AutoRec

Your calls are data. Don't lose them.

Every meeting, every negotiation, every support call — it's raw material for training models, building knowledge bases, and extracting insights. The problem is that this data evaporates the moment you hang up. AutoRec fixes that: it sits in your menu bar, detects calls automatically, and silently records everything — system audio, your microphone, and optionally your screen. After the call ends, it transcribes locally via whisper.cpp. No cloud, no subscriptions, no data leaving your machine. Just structured, searchable recordings accumulating on your disk, ready for whatever you build next.

## Features

- **Auto-detection** — monitors mic usage, starts recording the moment a call begins (Zoom, Teams, FaceTime, etc.)
- **Dual-track audio** — system audio (what you hear) and microphone (what you say) as separate files
- **Screen recording** — optional 10 fps H.264 capture, toggled from the menu
- **Local transcription** — whisper.cpp runs on your machine after each call, no API keys needed
- **Efficient codecs** — HE-AAC keeps files small (~5 MB/hour per track) while staying clear enough for speech recognition
- **Zero friction** — menu bar dot: gray = idle, red = recording. That's it.

## Build & Install

```bash
git clone https://github.com/huopolinen/AutoRec.git
cd AutoRec
bash build-app.sh
cp -r AutoRec.app /Applications/
```

macOS 13+ required. On first launch, grant **Microphone** and **Screen Recording** permissions.

## Usage

Click the menu bar icon:

- **Start/Stop Recording** — manual control
- **Pause/Resume** — mid-call pause
- **Auto-detect Calls** — fire-and-forget mode
- **Record Screen** — toggle screen capture
- **Auto-transcribe** — toggle post-call whisper.cpp transcription
- **Output folder** — choose where recordings land

Default output: `~/Downloads/AutoRec/`

| File | Contents |
|------|----------|
| `call_<timestamp>_system.m4a` | System audio (their voice) |
| `call_<timestamp>_mic.m4a` | Microphone (your voice) |
| `call_<timestamp>_screen.mp4` | Screen recording (if enabled) |
| `call_<timestamp>_transcript.txt` | Transcription (if enabled) |

## Audio Quality

| Track | Codec | Sample Rate | Bitrate |
|-------|-------|-------------|---------|
| System audio | HE-AAC v1 | 48 kHz stereo | 48 kbps |
| Microphone | HE-AAC v2 | 48 kHz mono | 32 kbps |

HE-AAC uses spectral band replication — full encoding of speech frequencies, compact reconstruction of highs. The result: clear voice at a fraction of the file size compared to AAC-LC.

## Transcription

```bash
brew install ffmpeg whisper-cpp
```

Download a model (base multilingual covers most languages, ~150 MB):

```bash
curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin" \
  -o /usr/local/share/whisper-cpp/ggml-base.bin
```

AutoRec auto-detects `whisper-cli` in PATH. Transcription runs locally after each recording — no API calls, no latency, no cost.

## License

MIT
