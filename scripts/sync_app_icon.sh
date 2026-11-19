#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SVG_SOURCE="$ROOT_DIR/docs/design-assets/Go2Claude-Icon-Final.svg"
APPICONSET_DIR="$ROOT_DIR/Resources/AppIcon.appiconset"
ICNS_OUTPUT="$ROOT_DIR/Resources/Go2Claude.icns"
FALLBACK_ICON="$APPICONSET_DIR/icon_1024x1024.png"

if [[ ! -f "$SVG_SOURCE" ]]; then
  echo "Icon source not found: $SVG_SOURCE" >&2
  exit 1
fi

if ! command -v rsvg-convert >/dev/null 2>&1; then
  if [[ -f "$ICNS_OUTPUT" && -f "$FALLBACK_ICON" ]]; then
    echo "==> rsvg-convert not found; reusing existing icon assets"
    exit 0
  fi

  echo "rsvg-convert is required to render the icon SVG." >&2
  exit 1
fi

if ! command -v iconutil >/dev/null 2>&1; then
  if [[ -f "$ICNS_OUTPUT" && -f "$FALLBACK_ICON" ]]; then
    echo "==> iconutil not found; reusing existing icon assets"
    exit 0
  fi

  echo "iconutil is required to create the macOS .icns bundle." >&2
  exit 1
fi

mkdir -p "$APPICONSET_DIR"

typeset -a ICON_SPECS=(
  "icon_16x16.png:16"
  "icon_16x16@2x.png:32"
  "icon_32x32.png:32"
  "icon_32x32@2x.png:64"
  "icon_64x64.png:64"
  "icon_64x64@2x.png:128"
  "icon_128x128.png:128"
  "icon_128x128@2x.png:256"
  "icon_256x256.png:256"
  "icon_256x256@2x.png:512"
  "icon_512x512.png:512"
  "icon_512x512@2x.png:1024"
  "icon_1024x1024.png:1024"
)

echo "==> Rendering app icon from Go2Claude-Icon-Final.svg"
for spec in "${ICON_SPECS[@]}"; do
  filename="${spec%%:*}"
  size="${spec##*:}"
  rsvg-convert -w "$size" -h "$size" "$SVG_SOURCE" -o "$APPICONSET_DIR/$filename"
done

tmp_dir="$(mktemp -d)"
iconset_dir="$tmp_dir/Go2Claude.iconset"
mkdir -p "$iconset_dir"
cp "$APPICONSET_DIR"/icon_*.png "$iconset_dir"/

echo "==> Building Go2Claude.icns"
iconutil -c icns "$iconset_dir" -o "$ICNS_OUTPUT"

rm -rf "$tmp_dir"

echo "Icon assets updated:"
echo "  $APPICONSET_DIR"
echo "  $ICNS_OUTPUT"
