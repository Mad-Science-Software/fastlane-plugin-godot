# Changelog

## 0.1.2 (2026-08-26) — GitHub only, unreleased on RubyGems

- `godot_export` now verifies the binary's version against the engine
  version the project declares in `config/features`, failing with guidance
  on mismatch (`skip_version_check: true` overrides), and discovers the
  Godot binary beyond `PATH` (common install locations, `GODOT`
  environment variable).
- `godot_install_templates` — download and install the export templates
  matching the binary's version, per platform or all; no-op when already
  installed, refuses prereleases with guidance.

## 0.1.1 (2026-08-26) — GitHub only, unreleased on RubyGems

- `godot_get_version` / `godot_set_version` — read and write version name +
  build number across every preset in `export_presets.cfg`, keeping iOS
  (`application/short_version` / `application/version`) and Android
  (`version/name` / `version/code`) in sync. Supports explicit values,
  semantic bumps (`major`/`minor`/`patch`), `build_number: 'increment'`,
  and `from_git: true` (version from the latest tag, build number from the
  commit count).

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
