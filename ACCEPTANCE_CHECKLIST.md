# Developer handoff acceptance checklist

Status is based on source inspection and the tests/build completed in this workspace. “Partial” means the feature exists but one or more stated requirements remain unimplemented or unverified. This checklist does not claim device-only performance or accessibility requirements have passed without device evidence.

| Handoff criterion | Status | Evidence / remaining work |
| --- | --- | --- |
| Android-first Flutter mobile application | **Pass** | Flutter Android debug APK builds at `build/app/outputs/flutter-apk/app-debug.apk`. |
| Self-paced offline lessons and local learner data; no recorded classes/live sessions | **Partial** | Lesson and progress flows are local; no classes or session service. First model download needs network. |
| W3Schools-style ordered Python course, Task 1 Introduction | **Partial** | Sample JSON pack has Tasks 1–3. Remaining Tasks 4–16 still draw from legacy Dart lesson definitions rather than content packs. |
| Every task has brief, full lesson, practical, and real-world mini project | **Partial** | Reader supports these sections for JSON tasks 1–3. The JSON pack coverage and fidelity need expansion to all course tasks. |
| Setup collects all specified learner preferences and personalizes starting plan | **Partial** | Name, age range, qualification, referral, experience, Python level, goal, daily time, learning style, language, and buddy are stored and used in the plan/prompt. Review exact age choices and persisted settings on device. |
| Named friend-style buddy, always addressing learner by name; scenario questions and varied answer types | **Partial** | Buddy name and learner name are injected into tutor prompts; practical UI supports yes/no, MCQ, typed code, fix-bug, and short answer. Confirm name usage and text quality across every prompt/response on device. |
| Correctness from runner or answer key, never from the LLM | **Pass for implemented practical types** | `AnswerEvaluator` and tests cover deterministic answer keys and runner output. No LLM correctness call is used. |
| Pyodide hidden worker, 3-second timeout, no host access | **Partial** | Pyodide 0.27.8 is bundled and checksummed; worker enforces a three-second timeout and restricts navigation/imports/files. Device runtime, memory cap (128 MB), and sandbox escape review remain unverified. |
| Qwen2.5-Coder-1.5B Q4 default; Qwen3-0.6B for weak devices; llama.cpp/MLC swappable interface | **Partial** | Swappable `TutorModel`, llama.cpp Android binding, separate resumable/checksummed model download, and memory-based choice are implemented. Model startup, compatibility matrix, and real memory thresholds need device verification. |
| JSON-constrained model output, 12-second timeout, prepared-hint fallback | **Partial** | 12-second timeout, JSON parsing/retry, and prepared hints exist. Native grammar-constrained decoding is unavailable through the selected plugin; output is prompt-constrained and parser-validated instead. |
| Dedicated chatbot with top-three lesson retrieval, restricted to Python topics | **Partial** | Dedicated tutor flow and top-three offline lexical retrieval exist. MiniLM/ONNX/TFLite semantic embeddings are not integrated, and topic restriction is prompt-level. |
| Difficulty 1–5, streak adaptation, pace/finish date, mastery, revision queue, reminders | **Partial** | Difficulty, streak rules, mastery, estimated finish, and revision queue have unit tests. Local scheduled reminders are not implemented; validate persisted per-topic mastery and pacing UI. |
| Approved visual system: 15 screens, floating cards, glossy icons, gradients, orange actions, Poppins, code font, light/dark | **Partial** | Theme, fonts, light/dark, and rounded card flows exist. Complete 15-screen-by-screen design comparison and missing glossy 3D tile assets are outstanding. |
| Versioned JSON content packs, loader, schema, sample Tasks 1–3; lessons not hard-coded | **Partial** | Schema, loader, and sample pack are present and tested for Tasks 1–3. Legacy syllabus/task definitions remain in Dart and must be migrated for the criterion to pass. |
| Base app under 60 MB, separate resumable/checksummed model download | **Partial** | Model is separate; resume and checksum validation are implemented. Current debug APK is ~192 MB across bundled ABIs. An optimized split release size has not been measured and the 60 MB target is unverified. |
| First AI token under 2 seconds | **Not verified** | Requires target-device cold/warm inference measurement and model-load design validation. |
| Fully usable offline | **Partial** | Bundled lessons, Pyodide, and local progress work offline. First model acquisition requires network; confirm all app flows and offline restart on device. |
| Learner data never leaves device | **Partial** | No application backend or account flow exists; prompts and progress are local. First model download contacts the model host. Verify telemetry/network behavior on device and in dependencies. |
| Accessibility criteria in handoff | **Not verified** | Requires a systematic screen-reader, text scaling, contrast, target-size, and reduced-motion audit against the attached document. |
| README, schema/sample pack, editable prompts, personalisation/evaluation tests | **Pass for delivered artifacts** | README, `assets/content/content-pack.schema.json`, `assets/content/en/python-v1.json`, `assets/prompts/`, and unit tests are present. |
| Unit tests and Android build | **Pass** | `flutter test --no-pub`: all 14 tests pass. `flutter build apk --debug --no-pub`: passed. Static analysis reports only two deprecated `RadioListTile` API informational diagnostics. |
| Physical Android acceptance run | **Not verified** | No Android device was available to the build session; the app was not launched on a handset after the latest changes. |

## Follow-up needed for full acceptance

1. Convert all course lessons and practicals to versioned JSON packs, then validate pack completeness.
2. Integrate and measure a local MiniLM embedding model for semantic retrieval; enforce model output with native grammar decoding if the selected llama.cpp binding supports it.
3. Implement local reminders and complete the specified accessibility audit.
4. Build optimized ABI-split release APKs, record each size, and profile cold start, first token, RAM use, offline behavior, and Pyodide isolation on supported low- and mid-range Android devices.
5. Compare all 15 screens and question flows against the handoff design/accessibility criteria on a physical device.
