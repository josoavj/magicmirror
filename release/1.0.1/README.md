# MagicMirror Release 1.0.1

Date: 2026-04-16
Type: Android APK + AAB (release)

## Version
- Version name: 1.0.1
- Version code: 2

## Artifacts
- File: magicmirror-v1.0.1.apk
- Path: release/1.0.1/magicmirror-v1.0.1.apk
- SHA-256: c12ed01767bdb3bb14dc57082612c7f46e3eb7c14ff97c7dd3d158bf722a7b91
- File: magicmirror-v1.0.1.aab
- Path: release/1.0.1/magicmirror-v1.0.1.aab
- SHA-256: 8c11506836513045401564b2f78ae5452a279808a60bd6b30b25ac68b0c33f90

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
