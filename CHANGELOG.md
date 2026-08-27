# Changelog

## 0.1.5 (2026-08-26) — GitHub only, unreleased on RubyGems

- Export smoke test now runs across a Godot version matrix — 4.2.2, 4.3.0,
  4.4.1, 4.5.1, 4.6.0, 4.7.1 — on every push; the README's
  supported-version claim comes from this matrix. Local multi-version
  checking via godot-ci Docker images documented in docs/CI.md.

## 0.1.4 (2026-08-26) — GitHub only, unreleased on RubyGems

- Reusable GitHub Actions workflows callable from game repositories:
  `godot-ios-testflight.yml` (macOS → TestFlight) and
  `godot-android-play.yml` (Linux → Play track), both installing Godot +
  templates via setup-godot.
- `docs/CI.md` — the CI signing recipe (temporary keychains via `setup_ci`,
  why `match` beats `get_certificates` on ephemeral runners, secret layout).
- Export smoke test in this repository's CI: headless Web export of a
  fixture project on Linux — engine updates can't silently break the
  export path, and `godot_export` is now Linux-verified.
- Example and scaffolded Fastfiles call `setup_ci` when running in CI.

## 0.1.3 (2026-08-26) — GitHub only, unreleased on RubyGems

- `godot_export` gains `install_android_build_template: true` for
  Gradle-based Android exports (Android App Bundles) — Godot only installs
  the project build template during an export invocation.
- `examples/android-play/` — Google Play walkthrough: debug APK vs release
  AAB, upload-keystore creation and Godot's `GODOT_ANDROID_KEYSTORE_RELEASE_*`
  environment variables, Play service-account setup, internal-track upload
  lane, and an Android sharp-edges table.

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
