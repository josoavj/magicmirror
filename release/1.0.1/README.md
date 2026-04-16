# MagicMirror Release 1.0.1

Date: 2026-04-16
Type: Android APK + AAB (release)

## Version
- Version name: 1.0.1
- Version code: 2

## Artifacts
- File: magicmirror-v1.0.1.apk
- Path: release/1.0.1/magicmirror-v1.0.1.apk
- SHA-256: 44d167de3e582a1ac828d395c824ac657985eb1b3ba6910d0ff89b8ecfbfd291
- File: magicmirror-v1.0.1.aab
- Path: release/1.0.1/magicmirror-v1.0.1.aab
- SHA-256: 17418bdddae95fa9df9d4339b0933fc49c575eaaae7824931f2bb30cabac2a73

## Build command used
```bash
flutter build apk --release --build-name=1.0.1 --build-number=2
flutter build appbundle --release --build-name=1.0.1 --build-number=2
```

## Notes
- Build Android release re-generated from branch UI.
- Artifacts copied and renamed to keep the same release folder convention.

## Install
```bash
adb install -r release/1.0.1/magicmirror-v1.0.1.apk
```
