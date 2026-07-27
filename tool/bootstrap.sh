#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found in PATH." >&2
  echo "Install Flutter, reopen the terminal, and run this script again." >&2
  exit 1
fi

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

flutter create \
  --project-name thought_circle \
  --org com.thoughtcircle \
  --platforms=android,ios,linux,macos,windows \
  "$scratch/scaffold"

for platform in android ios linux macos windows; do
  rm -rf "$platform"
  cp -R "$scratch/scaffold/$platform" "$platform"
done
cp "$scratch/scaffold/.metadata" .metadata

dart run tool/configure_platforms.dart
flutter pub get
flutter analyze
flutter test

echo "Thought Circle is ready. Run: flutter run"
