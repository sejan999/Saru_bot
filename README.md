# Saru Bot 🎙️✨

A futuristic, zero-friction AI voice assistant built with Flutter and powered by Google Gemini (`gemini-1.5-flash`).

## Features
- 🎤 Tap the glowing orb to talk — live speech-to-text via `speech_to_text`
- 🔊 Natural spoken replies via `flutter_tts`
- 🧠 Gemini-powered conversation with full multi-turn context
- ⚙️ In-app Settings dialog to save your Gemini API key (stored locally with `shared_preferences`) — the app never blocks on startup if no key is set
- 🌌 Dark futuristic UI with a state-driven animated orb (Idle / Listening / Processing / Speaking)
- 🏗️ One-tap cloud APK builds through GitHub Actions

## Build
```bash
flutter pub get
flutter build apk --release
```

Or simply push to `main` — the included GitHub Actions workflow (`.github/workflows/build_apk.yml`) builds and uploads `app-release.apk` as an artifact automatically.

## Getting an API key
Create a key at [Google AI Studio](https://aistudio.google.com/apikey), then open the gear icon inside the app and paste it. The key is saved on-device only.
