$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter was not found in PATH. Install Flutter and reopen PowerShell."
}

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("thought-circle-" + [guid]::NewGuid())
$scaffold = Join-Path $scratch "scaffold"
New-Item -ItemType Directory -Path $scratch | Out-Null

try {
  flutter create `
    --project-name thought_circle `
    --org com.thoughtcircle `
    --platforms=android,ios,linux,macos,windows `
    $scaffold

  foreach ($platform in @("android", "ios", "linux", "macos", "windows")) {
    if (Test-Path $platform) { Remove-Item $platform -Recurse -Force }
    Copy-Item (Join-Path $scaffold $platform) $platform -Recurse
  }
  Copy-Item (Join-Path $scaffold ".metadata") ".metadata" -Force

  dart run tool/configure_platforms.dart
  flutter pub get
  flutter analyze
  flutter test
  Write-Host "Thought Circle is ready. Run: flutter run"
}
finally {
  if (Test-Path $scratch) { Remove-Item $scratch -Recurse -Force }
}
