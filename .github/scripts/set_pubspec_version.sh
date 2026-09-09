#!/usr/bin/env bash
# 把 Release tag 写成 Flutter 可解析的 pubspec version。
# 手动运行时 tag 是 manual-<sha>，不能直接写入 pubspec.yaml。
set -euo pipefail

TAG="${1:-}"
BUILD_NUMBER="${2:-1}"
PUBSPEC="${3:-pubspec.yaml}"

if [[ -z "$TAG" ]]; then
  echo "usage: $0 <tag> [build_number] [pubspec.yaml]" >&2
  exit 1
fi

STRIPPED="${TAG#v}"
CORE="${STRIPPED%%+*}"

if [[ "$CORE" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  PUB_VERSION="$CORE"
else
  PUB_VERSION="$(awk '/^version:/ { sub(/^version:[[:space:]]*/, ""); sub(/\+.*/, ""); gsub(/[[:space:]]/, ""); print; exit }' "$PUBSPEC")"
  if [[ ! "$PUB_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    PUB_VERSION="1.0.0"
  fi
  echo "Tag '$TAG' is not a Dart semver; using pubspec version $PUB_VERSION"
fi

NEW_VERSION="${PUB_VERSION}+${BUILD_NUMBER}"
echo "Setting $PUBSPEC version to: $NEW_VERSION"

tmp="$(mktemp)"
awk -v v="$NEW_VERSION" '
  /^version:/ { print "version: " v; next }
  { print }
' "$PUBSPEC" > "$tmp"
mv "$tmp" "$PUBSPEC"

grep "^version:" "$PUBSPEC"
