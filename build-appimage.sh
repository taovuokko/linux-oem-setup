#!/usr/bin/env bash
# Build and optionally test the AppImage locally — mirrors the GitHub Actions pipeline.
# Run this on Ubuntu 24.04 (or in an Ubuntu 24.04 container/VM).
#
# Usage:
#   ./build-appimage.sh          # build only
#   ./build-appimage.sh --test   # build + run AppImage with --mock flag

set -euo pipefail

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPTDIR"

# ── 1. Dependencies ────────────────────────────────────────────────────────────
echo "==> Checking / installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y \
  qt6-base-dev qt6-declarative-dev qt6-svg-dev \
  qt6-tools-dev qt6-tools-dev-tools \
  cmake ninja-build pkg-config \
  libgl1-mesa-dev libopengl0 libglib2.0-dev \
  qml6-module-qtquick \
  qml6-module-qtquick-controls \
  qml6-module-qtquick-layouts \
  qml6-module-qtquick-templates \
  qml6-module-qtquick-window \
  qml6-module-qtqml-workerscript \
  libfuse2

# ── 2. Build ───────────────────────────────────────────────────────────────────
echo "==> Building..."
cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build --parallel

# ── 3. Quick sanity check with native binary ───────────────────────────────────
echo "==> Smoke-testing native binary (closes after 3 s)..."
timeout 3 env LIBGL_ALWAYS_SOFTWARE=1 QT_QPA_PLATFORM=offscreen \
  ./build/src/gui/oem-setup-gui --mock || true

# ── 4. Install to AppDir ───────────────────────────────────────────────────────
echo "==> Installing to AppDir..."
rm -rf AppDir
DESTDIR=AppDir cmake --install build

# Deploy OemSetup QML module (not handled by cmake install or linuxdeploy).
# Strip the "prefer :/..." hint so Qt uses the filesystem copy unconditionally.
mkdir -p AppDir/usr/qml/OemSetup
grep -v '^prefer ' build/src/gui/OemSetup/qmldir \
  > AppDir/usr/qml/OemSetup/qmldir
cp -r build/src/gui/OemSetup/qml AppDir/usr/qml/OemSetup/
find build/src/gui -name "liboem-setup-guiplugin.so" \
  -exec cp {} AppDir/usr/qml/OemSetup/ \; 2>/dev/null || true

echo "==> AppDir/usr/qml/OemSetup/ contents:"
find AppDir/usr/qml/OemSetup -type f | sort

# ── 5. Download linuxdeploy (once) ────────────────────────────────────────────
if [[ ! -x linuxdeploy ]]; then
  echo "==> Downloading linuxdeploy..."
  curl -fsSLo linuxdeploy \
    https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
  curl -fsSLo linuxdeploy-plugin-qt \
    https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
  chmod +x linuxdeploy linuxdeploy-plugin-qt
fi

# ── 6. Build AppImage ──────────────────────────────────────────────────────────
echo "==> Building AppImage..."
OUTPUT=oem-setup-test.AppImage \
APPIMAGE_EXTRACT_AND_RUN=1 \
QMAKE=/usr/bin/qmake6 \
QML_SOURCES_PATHS="$SCRIPTDIR/src/gui/qml" \
  ./linuxdeploy --appimage-extract-and-run \
    --appdir AppDir \
    --plugin qt \
    --output appimage

echo ""
echo "==> AppImage built: oem-setup-test.AppImage"
echo "==> Verifying OemSetup module is present in AppImage..."
./oem-setup-test.AppImage --appimage-extract >/dev/null 2>&1
PRESENT=$(find squashfs-root/usr/qml/OemSetup -name "qmldir" 2>/dev/null | wc -l)
rm -rf squashfs-root
if [[ "$PRESENT" -gt 0 ]]; then
  echo "    OK — OemSetup/qmldir found in AppImage."
else
  echo "    FAIL — OemSetup/qmldir NOT found in AppImage!"
  exit 1
fi

# ── 7. Optional: test run ─────────────────────────────────────────────────────
if [[ "${1:-}" == "--test" ]]; then
  echo ""
  echo "==> Running AppImage (close the window or Ctrl+C to stop)..."
  LIBGL_ALWAYS_SOFTWARE=1 ./oem-setup-test.AppImage --mock
fi

echo ""
echo "Done."
