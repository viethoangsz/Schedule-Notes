---
name: Flutter APK build quota
description: Replit free tier disk quota prevents Flutter Android APK builds; GitHub Actions is the workaround.
---

## Rule
Do NOT attempt to build Flutter Android APKs inside Replit free tier — the disk quota (~5GB) is too small.

## Why
Flutter's `dev.flutter.flutter-gradle-plugin` unconditionally requires NDK 27.0.12077973 (~2GB). This is set by the Flutter Gradle plugin itself and cannot be suppressed via `local.properties` or `build.gradle.kts`. When Gradle also creates its transform cache (~2GB) and adds the Android SDK (~0.6GB), the total exceeds Replit's per-user quota (~5GB), causing `java.io.IOException: Disk quota exceeded`.

Attempts made (all failed due to quota):
- Removing NDK pre-install → Gradle auto-downloads it anyway
- Setting `ndk.dir` to empty → Flutter Gradle plugin overrides it
- Moving `GRADLE_USER_HOME` to `/tmp` → same filesystem, same quota
- Disabling `coreLibraryDesugaring` → reduces transforms by ~30% but not enough
- Setting `minSdk = 26` → smaller, still not enough

## How to apply
When the user wants an APK, direct them to:
1. **GitHub Actions** — `.github/workflows/build-apk.yml` is already in the project; push to GitHub and the APK downloads automatically as an artifact.
2. **Build locally** — `flutter build apk --debug --target-platform android-arm64`
3. **Codemagic** — free Flutter CI at codemagic.io

The project code is complete and correct. Only the build environment is the blocker.
