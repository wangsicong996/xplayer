#!/usr/bin/env bash
# 从 Flutter Linux bundle 打出 x86_64 AppImage。
# 产物可用 --appimage-extract 解压成 squashfs-root，再放进 Flatpak。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="${1:-$ROOT/build/linux/x64/release/bundle}"
OUT="${2:-$ROOT/xplayer-linux-x64.AppImage}"
PACKAGING="$ROOT/linux/packaging"
ICON="${ICON:-$ROOT/assets/images/xplayer-logo.png}"
APPIMAGETOOL_URL="${APPIMAGETOOL_URL:-https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage}"

if [[ ! -x "$BUNDLE/xplayer" ]]; then
  echo "Flutter Linux bundle not found at: $BUNDLE" >&2
  echo "Run: flutter build linux --release" >&2
  exit 1
fi
if [[ ! -f "$ICON" ]]; then
  echo "Icon not found: $ICON" >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

APPDIR="$WORKDIR/AppDir"
mkdir -p "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# 保持 Flutter bundle 布局（可执行文件旁必须有 lib/ 和 data/）
cp -a "$BUNDLE/." "$APPDIR/"
cp "$PACKAGING/xplayer.desktop" "$APPDIR/xplayer.desktop"
cp "$PACKAGING/xplayer.desktop" "$APPDIR/usr/share/applications/xplayer.desktop"
cp "$ICON" "$APPDIR/xplayer.png"
cp "$ICON" "$APPDIR/usr/share/icons/hicolor/256x256/apps/xplayer.png"
cp "$PACKAGING/AppRun" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun" "$APPDIR/xplayer"
mkdir -p "$APPDIR/usr/bin"
ln -sfn ../../xplayer "$APPDIR/usr/bin/xplayer"

if [[ "$OUT" != /* ]]; then
  OUT="$(pwd)/$OUT"
fi
mkdir -p "$(dirname "$OUT")"

TOOL="$WORKDIR/appimagetool.AppImage"
echo "Downloading appimagetool..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL -o "$TOOL" "$APPIMAGETOOL_URL"
else
  wget -q -O "$TOOL" "$APPIMAGETOOL_URL"
fi
chmod +x "$TOOL"

# GitHub runner / 容器通常没有 FUSE，用官方开关解到临时目录再执行。
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$TOOL" --no-appstream "$APPDIR" "$OUT"
chmod +x "$OUT"
echo "Wrote $OUT"
ls -lh "$OUT"
