# Changelog

## 0.1.0 (2026-08-26)

Initial release.

- `godot_export` — headless preset export with diagnostics: preset
  validation, export-template verification per platform, resource import
  before export (stale caches abort exports), output-directory creation,
  and artifact-existence checking (Godot can exit 0 on failed exports).
- `godot_init` — idempotent scaffolding of everything a Godot project
  needs for fastlane mobile releases: Gemfile, fastlane configuration,
  `.env` template, iOS + Android export presets, `build/.gdignore`,
  placeholder app icon, `.gitignore`.
- `examples/ios-testflight/` — from-zero walkthrough to a TestFlight
  build, including App Store Connect API-key signing without cloud
  signing, and a sharp-edges table mapping exact error messages to fixes.
- Verified on Godot 4.7.1: iOS (App Store `.ipa`, TestFlight-distributed,
  device-tested) and Android (debug-signed arm64 APK, targetSdk 36).
