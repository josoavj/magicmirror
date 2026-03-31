# MagicMirror Release 1.0.0-beta

Date: 2026-04-01
Type: Android APK + AAB (release)

## Version
- Version name: 1.0.0-beta
- Version code: 1

## Artifacts
- File: magicmirror-v1.0.0-beta.apk
- Path: release/1.0.0-beta/magicmirror-v1.0.0-beta.apk
- SHA-256: bb72f77dd45b79d44b866a90627b4bf0fb142536289e6df9601686119acf04e7
- File: magicmirror-v1.0.0-beta.aab
- Path: release/1.0.0-beta/magicmirror-v1.0.0-beta.aab
- SHA-256: 3af5e36dc006460846a75dc649d89979409e482a0e24aa0fe0e7dc74193548ed

## Build command used
```bash
flutter build apk --release --build-name=1.0.0-beta --build-number=1
flutter build appbundle --release --build-name=1.0.0-beta --build-number=1
```

## Notes
- R8/ProGuard release rules were added for optional ML Kit text recognition language classes to avoid release build failures.
- Release signing currently uses debug signing config in android/app/build.gradle.kts.

## Install
```bash
adb install -r release/1.0.0-beta/magicmirror-v1.0.0-beta.apk
```
