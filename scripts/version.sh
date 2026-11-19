#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MAIN_INFO_PLIST="$ROOT_DIR/Resources/Info.plist"
TOOLBAR_INFO_PLIST="$ROOT_DIR/Resources/Go2ClaudeToolbar-Info.plist"

# 获取当前版本号
MAIN_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$MAIN_INFO_PLIST")"
TOOLBAR_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$TOOLBAR_INFO_PLIST")"

echo "Current Versions:"
echo "  Go2Claude:        $MAIN_VERSION"
echo "  Go2Claude Toolbar: $TOOLBAR_VERSION"

if [[ "$MAIN_VERSION" != "$TOOLBAR_VERSION" ]]; then
  echo ""
  echo "⚠️  Warning: Version mismatch!"
  exit 1
fi

echo ""
echo "Commands:"
echo "  ./scripts/version.sh increment     # Increment patch version (1.2.0 -> 1.2.1)"
echo "  ./scripts/version.sh set 1.3.0     # Set specific version"
echo "  ./scripts/version.sh               # Show current version"

# 处理命令
COMMAND="${1:-}"

case "$COMMAND" in
  increment)
    IFS='.' read -r major minor patch <<< "$MAIN_VERSION"
    new_patch=$((patch + 1))
    NEW_VERSION="${major}.${minor}.${new_patch}"
    
    echo ""
    echo "Incrementing version: $MAIN_VERSION -> $NEW_VERSION"
    
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$MAIN_INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION" "$MAIN_INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$TOOLBAR_INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION" "$TOOLBAR_INFO_PLIST"
    
    echo "✓ Version updated to $NEW_VERSION"
    ;;
    
  set)
    if [[ -z "${2:-}" ]]; then
      echo "Error: Version required. Usage: $0 set 1.3.0" >&2
      exit 1
    fi
    NEW_VERSION="$2"
    
    echo ""
    echo "Setting version: $MAIN_VERSION -> $NEW_VERSION"
    
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$MAIN_INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION" "$MAIN_INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$TOOLBAR_INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION" "$TOOLBAR_INFO_PLIST"
    
    echo "✓ Version set to $NEW_VERSION"
    ;;
    
  "")
    # No command, just show version
    ;;
    
  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Usage: $0 [increment|set <version>]" >&2
    exit 1
    ;;
esac
