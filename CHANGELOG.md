# Changelog

## 0.2.2 (2026-08-27)

Documentation release, after verifying the full CI pipeline live (a real
game built and uploaded to TestFlight from a GitHub macOS runner):

- `examples/ci-testflight-no-mac/` — project-agnostic walkthrough for
  shipping to TestFlight from CI without owning a Mac: certificates repo +
  `match`, read-only deploy key, repository secrets, a CI-safe
  manual-signing Fastfile, and a copyable caller workflow.
- `docs/CI.md` — two live-run lessons: OpenSSL-built empty-password `.p12`
  files fail fresh-keychain import (export with Apple tooling instead),
  and CI archives need manual signing with the match identity.
- iOS reusable workflow accepts `MATCH_GIT_PRIVATE_KEY` (deploy-key
  clones) and a `match-git-url` override.
- README: RubyGems/CI badges and gem link.

## 0.2.1 (2026-08-27)

First-hour fixes from a blind third-party usability test:

- `godot_init` enables `textures/vram_compression/import_etc2_astc` in
  `project.godot` (Android export refuses projects without it, and Godot's
  own error suggests an editor-GUI fix) and drops `.gdignore` files into
  `vendor/` and `.bundle/` — without them, bundler's `path vendor/bundle`
  setup got the fastlane gems packed into the exported game.
- Scaffolded/example iOS lanes export before touching credentials, and a
  missing `ASC_*` variable now produces "copy fastlane/.env.template…"
  instead of a raw Ruby `KeyError`.
- `godot_set_version from_git:` distinguishes "not a git repository" from
  "no tags".
- Import/export per-file progress noise is hidden unless `verbose: true`
  (failures still raise with full output).
- Docs: ETC2/ASTC and vendored-gems rows in the sharp-edges tables; stale
  README roadmap paragraph and parity table refreshed.
- CI: Android APK export smoke test on a Linux runner (dogfooding the
  docs/CI.md editor-settings + debug-keystore recipe) — Linux Android
  builds are now verified, completing the parity roadmap; ROADMAP.md is
  retired (its standing quality bar lives in the README, its history in
  this changelog and git).

## 0.2.0 (2026-08-27)

Everything from the 0.1.1–0.1.5 development tags, published:

- Version management: `godot_get_version` / `godot_set_version`
  (cross-preset sync, semantic bumps, git-derived mode)
- Engine resolution: project-declared version verification, binary
  discovery beyond `PATH`, `godot_install_templates`
- Android App Bundles: `install_android_build_template` option +
  the `examples/android-play/` walkthrough
- CI: reusable ios-testflight / android-play workflows, `docs/CI.md`
- Godot 4.2–4.7 support enforced by a CI export matrix

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
