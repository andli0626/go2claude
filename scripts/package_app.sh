#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build"
DIST_DIR="$ROOT_DIR/dist"
INCLUDE_ZIP="${INCLUDE_ZIP:-0}"
BUILD_ARCHS=(${=PACKAGE_ARCHS:-arm64 x86_64})
SWIFT_BUILD_JOBS="${SWIFT_BUILD_JOBS:-}"
MAIN_APP_NAME="Go2Claude"
MAIN_EXECUTABLE_NAME="Go2Claude"
TOOLBAR_APP_NAME="Go2Claude Toolbar"
TOOLBAR_EXECUTABLE_NAME="Go2ClaudeToolbar"
MAIN_APP_DIR="$DIST_DIR/$MAIN_APP_NAME.app"
TOOLBAR_APP_DIR="$DIST_DIR/$TOOLBAR_APP_NAME.app"
MAIN_INFO_PLIST_SOURCE="$ROOT_DIR/Resources/Info.plist"
TOOLBAR_INFO_PLIST_SOURCE="$ROOT_DIR/Resources/Go2ClaudeToolbar-Info.plist"
INSTALL_README_SOURCE="$ROOT_DIR/Resources/README-安装说明.txt"
INSTALL_README_PATH="$DIST_DIR/README-安装说明.txt"
ZIP_STAGE_DIR="$DIST_DIR/Go2Claude"
ZIP_PATH="$DIST_DIR/$MAIN_APP_NAME.zip"
PKG_ROOT_DIR="$DIST_DIR/pkg-root"
PKG_PATH="$DIST_DIR/$MAIN_APP_NAME.pkg"
ICON_SYNC_SCRIPT="$ROOT_DIR/scripts/sync_app_icon.sh"
PACKAGE_IDENTIFIER="com.lilin.Go2Claude"

# 版本号自动递增功能
AUTO_INCREMENT_VERSION="${AUTO_INCREMENT_VERSION:-0}"

# 获取当前版本号
PACKAGE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$MAIN_INFO_PLIST_SOURCE")"
TOOLBAR_PACKAGE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$TOOLBAR_INFO_PLIST_SOURCE")"

if [[ "$AUTO_INCREMENT_VERSION" == "1" ]]; then
  echo "==> Auto-incrementing version..."
  
  # 解析版本号 (假设格式为 X.Y.Z)
  IFS='.' read -r major minor patch <<< "$PACKAGE_VERSION"
  
  # 递增 patch 版本号
  new_patch=$((patch + 1))
  NEW_VERSION="${major}.${minor}.${new_patch}"
  
  echo "==> Version: $PACKAGE_VERSION -> $NEW_VERSION"
  
  # 更新主应用的 Info.plist
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$MAIN_INFO_PLIST_SOURCE"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION" "$MAIN_INFO_PLIST_SOURCE"
  
  # 更新 Toolbar 应用的 Info.plist
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$TOOLBAR_INFO_PLIST_SOURCE"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION" "$TOOLBAR_INFO_PLIST_SOURCE"
  
  # 更新版本号变量
  PACKAGE_VERSION="$NEW_VERSION"
  TOOLBAR_PACKAGE_VERSION="$NEW_VERSION"
fi

RELEASE_DATE="${RELEASE_DATE:-$(date +%Y%m%d)}"
RELEASE_BASENAME="${MAIN_APP_NAME}-macOS-universal-${PACKAGE_VERSION}-${RELEASE_DATE}"
VERSIONED_ZIP_PATH="$DIST_DIR/$RELEASE_BASENAME.zip"
VERSIONED_PKG_PATH="$DIST_DIR/$RELEASE_BASENAME.pkg"

if [[ "$PACKAGE_VERSION" != "$TOOLBAR_PACKAGE_VERSION" ]]; then
  echo "App version mismatch: $MAIN_INFO_PLIST_SOURCE=$PACKAGE_VERSION, $TOOLBAR_INFO_PLIST_SOURCE=$TOOLBAR_PACKAGE_VERSION" >&2
  exit 1
fi

swift_release_build_args=(
  -c release
  --package-path "$ROOT_DIR"
)

for arch in "${BUILD_ARCHS[@]}"; do
  swift_release_build_args+=(--arch "$arch")
done

if [[ -n "$SWIFT_BUILD_JOBS" ]]; then
  swift_release_build_args+=(--jobs "$SWIFT_BUILD_JOBS")
fi

resolve_release_binary_path() {
  local executable_name="$1"
  local bin_dir

  bin_dir="$(swift build "${swift_release_build_args[@]}" --show-bin-path)"
  echo "$bin_dir/$executable_name"
}

create_app_bundle() {
  local app_dir="$1"
  local executable_name="$2"
  local executable_path="$3"
  local info_plist_source="$4"
  local contents_dir="$app_dir/Contents"
  local macos_dir="$contents_dir/MacOS"
  local resources_dir="$contents_dir/Resources"

  rm -rf "$app_dir"
  mkdir -p "$macos_dir" "$resources_dir"

  cp "$executable_path" "$macos_dir/$executable_name"
  cp "$info_plist_source" "$contents_dir/Info.plist"

  if [[ -f "$ROOT_DIR/Resources/Go2Claude.icns" ]]; then
    cp "$ROOT_DIR/Resources/Go2Claude.icns" "$resources_dir/Go2Claude.icns"
  fi

  chmod +x "$macos_dir/$executable_name"
}

if [[ -x "$ICON_SYNC_SCRIPT" ]]; then
  "$ICON_SYNC_SCRIPT"
else
  echo "==> Icon sync script is not executable, skipping icon regeneration"
fi

echo "==> Building release executables"
echo "==> Target architectures: ${BUILD_ARCHS[*]}"
swift build "${swift_release_build_args[@]}" --product "$MAIN_EXECUTABLE_NAME"
swift build "${swift_release_build_args[@]}" --product "$TOOLBAR_EXECUTABLE_NAME"

MAIN_EXECUTABLE_PATH="$(resolve_release_binary_path "$MAIN_EXECUTABLE_NAME")"
TOOLBAR_EXECUTABLE_PATH="$(resolve_release_binary_path "$TOOLBAR_EXECUTABLE_NAME")"

if [[ ! -f "$MAIN_EXECUTABLE_PATH" ]]; then
  echo "Release executable not found at $MAIN_EXECUTABLE_PATH" >&2
  exit 1
fi

if [[ ! -f "$TOOLBAR_EXECUTABLE_PATH" ]]; then
  echo "Release executable not found at $TOOLBAR_EXECUTABLE_PATH" >&2
  exit 1
fi

echo "==> Creating app bundles"
rm -rf "$PKG_ROOT_DIR" "$PKG_PATH" "$ZIP_STAGE_DIR" "$ZIP_PATH" "$VERSIONED_PKG_PATH" "$VERSIONED_ZIP_PATH" "$INSTALL_README_PATH"
create_app_bundle "$MAIN_APP_DIR" "$MAIN_EXECUTABLE_NAME" "$MAIN_EXECUTABLE_PATH" "$MAIN_INFO_PLIST_SOURCE"
create_app_bundle "$TOOLBAR_APP_DIR" "$TOOLBAR_EXECUTABLE_NAME" "$TOOLBAR_EXECUTABLE_PATH" "$TOOLBAR_INFO_PLIST_SOURCE"

if [[ -f "$INSTALL_README_SOURCE" ]]; then
  cp "$INSTALL_README_SOURCE" "$INSTALL_README_PATH"
fi

if [[ "$INCLUDE_ZIP" == "1" ]]; then
  echo "==> Creating zip archive"
  mkdir -p "$ZIP_STAGE_DIR"
  ditto "$MAIN_APP_DIR" "$ZIP_STAGE_DIR/$MAIN_APP_NAME.app"
  ditto "$TOOLBAR_APP_DIR" "$ZIP_STAGE_DIR/$TOOLBAR_APP_NAME.app"
  if [[ -f "$INSTALL_README_PATH" ]]; then
    cp "$INSTALL_README_PATH" "$ZIP_STAGE_DIR/README-安装说明.txt"
  fi
  ditto -c -k --sequesterRsrc --keepParent "$ZIP_STAGE_DIR" "$ZIP_PATH"
  cp "$ZIP_PATH" "$VERSIONED_ZIP_PATH"
fi

echo "==> Creating installer package"
mkdir -p "$PKG_ROOT_DIR/Applications"
ditto "$MAIN_APP_DIR" "$PKG_ROOT_DIR/Applications/$MAIN_APP_NAME.app"
ditto "$TOOLBAR_APP_DIR" "$PKG_ROOT_DIR/Applications/$TOOLBAR_APP_NAME.app"
pkgbuild --identifier "$PACKAGE_IDENTIFIER" --version "$PACKAGE_VERSION" --root "$PKG_ROOT_DIR" --install-location / "$PKG_PATH" >/dev/null
cp "$PKG_PATH" "$VERSIONED_PKG_PATH"
rm -rf "$ZIP_STAGE_DIR"
rm -rf "$PKG_ROOT_DIR"

echo "==> Verifying bundled Info.plist"
if ! /usr/bin/plutil -extract LSUIElement raw "$MAIN_APP_DIR/Contents/Info.plist" | /usr/bin/grep -Eqx '1|true'; then
  echo "LSUIElement is not enabled in $MAIN_APP_NAME.app" >&2
  exit 1
fi

if ! /usr/bin/plutil -extract LSUIElement raw "$TOOLBAR_APP_DIR/Contents/Info.plist" | /usr/bin/grep -Eqx '1|true'; then
  echo "LSUIElement is not enabled in $TOOLBAR_APP_NAME.app" >&2
  exit 1
fi

echo "==> Verifying universal binaries"
main_archs="$(lipo -archs "$MAIN_APP_DIR/Contents/MacOS/$MAIN_EXECUTABLE_NAME")"
toolbar_archs="$(lipo -archs "$TOOLBAR_APP_DIR/Contents/MacOS/$TOOLBAR_EXECUTABLE_NAME")"
echo "  $MAIN_EXECUTABLE_NAME: $main_archs"
echo "  $TOOLBAR_EXECUTABLE_NAME: $toolbar_archs"

echo "Packaged apps:"
echo "  $MAIN_APP_DIR"
echo "  $TOOLBAR_APP_DIR"
echo "  $INSTALL_README_PATH"
echo "  $PKG_PATH"
echo "  $VERSIONED_PKG_PATH"
if [[ "$INCLUDE_ZIP" == "1" ]]; then
  echo "  $ZIP_PATH"
  echo "  $VERSIONED_ZIP_PATH"
fi
echo "If Finder toolbar still points to an older app bundle, remove the old button and drag the new dist/Go2Claude Toolbar.app into the Finder toolbar again."

echo ""
echo "==> Usage Tips:"
echo "  Auto-increment version: AUTO_INCREMENT_VERSION=1 ./scripts/package_app.sh"
echo "  Include ZIP archive: INCLUDE_ZIP=1 ./scripts/package_app.sh"
echo "  Both options: AUTO_INCREMENT_VERSION=1 INCLUDE_ZIP=1 ./scripts/package_app.sh"
