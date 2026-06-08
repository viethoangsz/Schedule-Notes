#!/usr/bin/env bash
set -e

# Use /tmp for ALL android SDK and Gradle caches to avoid home directory quota
ANDROID_HOME="/tmp/android-sdk"
export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"

# Redirect Gradle user home to /tmp to avoid quota
export GRADLE_USER_HOME="/tmp/.gradle"
mkdir -p "$GRADLE_USER_HOME"

# Fix JVM SIGBUS crash in containerized environments
export JAVA_TOOL_OPTIONS="-XX:-UsePerfData -XX:-TieredCompilation -Djava.io.tmpdir=/tmp"
export GRADLE_OPTS="-XX:-UsePerfData -Djava.io.tmpdir=/tmp"
export _JAVA_OPTIONS="-XX:-UsePerfData"

CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
CMDLINE_ZIP="/tmp/cmdline-tools.zip"

echo "=== [1/5] Kiem tra cmdline-tools ==="
if [ ! -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "Tai cmdline-tools..."
  curl -Lo "$CMDLINE_ZIP" "$CMDLINE_TOOLS_URL"
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  unzip -q "$CMDLINE_ZIP" -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" 2>/dev/null || true
  rm -f "$CMDLINE_ZIP"
  echo "cmdline-tools OK"
else
  echo "cmdline-tools da co."
fi

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

echo "=== [2/5] Chap nhan licenses ==="
yes | "$SDKMANAGER" --licenses > /dev/null 2>&1 || true

echo "=== [3/5] Kiem tra SDK platforms ==="
if [ ! -d "$ANDROID_HOME/platforms/android-35" ]; then
  echo "Cai platform-tools + build-tools + platforms..."
  "$SDKMANAGER" "platform-tools" "build-tools;35.0.0" "platforms;android-35"
  echo "SDK OK"
else
  echo "platforms/android-35 da co."
fi

echo "=== Disk usage ==="
df -h /home/runner
df -h /tmp
du -sh /tmp/android-sdk/ 2>/dev/null || true

echo "=== [4/5] Cap nhat local.properties ==="
FLUTTER_SDK=$(dirname "$(dirname "$(which flutter)")")
cat > /home/runner/workspace/android/local.properties <<EOF
sdk.dir=$ANDROID_HOME
flutter.sdk=$FLUTTER_SDK
EOF
echo "local.properties OK"

echo "=== [5/5] Build APK Debug ==="
cd /home/runner/workspace
flutter pub get

flutter pub run flutter_launcher_icons 2>/dev/null || true

flutter build apk --debug \
  --target-platform android-arm64 \
  --no-tree-shake-icons

echo ""
APK_PATH="/home/runner/workspace/build/app/outputs/flutter-apk/app-debug.apk"
if [ -f "$APK_PATH" ]; then
  SIZE=$(du -sh "$APK_PATH" | cut -f1)
  echo "============================================"
  echo "BUILD THANH CONG!"
  echo "APK: $APK_PATH"
  echo "Kich thuoc: $SIZE"
  echo "============================================"
else
  echo "APK khong tim thay!"
  find /home/runner/workspace/build -name "*.apk" 2>/dev/null || echo "No APKs found"
  exit 1
fi
