# Easy Python

An Android-first, offline-first Flutter app for learning Python through short lessons, deterministic practice, and an optional on-device AI tutor. The AI explains and gives hints; answer evaluation is handled by the answer key or the local Python runner.

## Build and run

Requirements: Flutter SDK compatible with the SDK constraint in `pubspec.yaml`, Android SDK, and an Android device or emulator.

```sh
flutter pub get
flutter test
flutter run
```

Create a debug APK with `flutter build apk --debug`. The tutor's GGUF model is downloaded separately to app storage on first use, with resume and SHA-256 validation. The model is not included in the app package. Internet is needed for that first model download; lessons and practice remain available offline.

## Learning content

Versioned lesson content is stored under `assets/content/`. `assets/content/content-pack.schema.json` describes the JSON format. `assets/content/en/python-v1.json` is a sample pack with Tasks 1–3: Introduction, Get Started, and Syntax. `ContentPackLoader` loads packs, and `LessonRetriever` returns up to three offline lesson passages for the tutor.

The setup flow records learner preferences and builds a starting plan. The lesson reader presents the brief, lesson, examples, recap, and a practical task. Practical question types include multiple choice, yes/no, short written responses, typed code, and fix-the-bug. For code questions, Pyodide runs inside a local hidden WebView worker with a three-second timeout; correctness comes from test output. The chatbot retrieves lesson context and is restricted by its editable prompt templates in `assets/prompts/`.

## On-device tutor

`TutorModel` is the swappable inference interface. Android uses llama.cpp through `llama_flutter_android`; the standard model is Qwen2.5-Coder-1.5B-Instruct Q4, and the small-device selection is Qwen3-0.6B Q4. The tutor uses JSON-shaped prompts, validates the response, retries once, and falls back to prepared hints. This Flutter plugin does not expose grammar-based constrained decoding, so JSON validity is enforced by parsing and fallback rather than a native grammar constraint.

No OpenAI API key, server, account, or cloud inference is configured. Learner progress is stored locally with SharedPreferences.

## Verification and known gaps

Run `flutter test --no-pub` for unit tests. The handoff review matrix is in `ACCEPTANCE_CHECKLIST.md`; it distinguishes implemented and verified behavior from work that still needs implementation or an Android device check. In particular, semantic MiniLM embeddings, local reminders, complete JSON task packs for Tasks 4–16, on-device model latency/memory measurements, and the 60 MB release package target are not yet verified as satisfied. The current debug APK includes native libraries for multiple Android ABIs and is not a measure of the optimized split release APK size.
