# Roadmap

Goal: reach — then pass — feature parity with the Unity fastlane plugins
(chiefly [fastlane-plugin-unity_exporter](https://github.com/ar-met/fastlane-plugin-unity-exporter)),
while keeping the two advantages we already have: real diagnostics and
from-zero documentation. Parity mapping is at the bottom.

Versions are milestones, not promises of scope-freeze; each ships when its
checklist is green and dogfooded against a real game.

## v0.1.0 — RubyGems release

The Unity plugins earn ~90K installs largely on name and discoverability;
`fastlane add_plugin godot` must work. **Gate: Android export verified
first** — the first public impression must cover both mobile platforms, so
the v0.4.0 Android-export checklist item (verify `godot_export` against
Android presets) moves into this milestone; the Play-upload example and
deep documentation stay in v0.4.0.

- [x] `godot_export` verified against an Android preset (APK at minimum)
      on a real game — Crunch, Godot 4.7.1: debug-signed arm64 APK,
      targetSdk 36, via `godot_export(preset: 'Android', debug: true)`
- [x] Publish `fastlane-plugin-godot` to RubyGems (0.1.0, 2026-08-26)
- [x] Tag releases; start a CHANGELOG
- [x] Switch README / example Pluginfile to the gem install
- [x] Issue templates (bug report asks for Godot version, preset, full
      export output)

## v0.2.0 — Version & build-number management

unity_exporter's headline feature, and the piece our own pipeline wants
(versions derived from git tags, never hand-bumped).

- [x] `godot_get_version` — read `application/short_version` /
      `application/version` from a preset (shipped v0.1.1)
- [x] `godot_set_version` — write them; semantic increments
      (`major`/`minor`/`patch`) and explicit values; iOS version/build and
      Android version/code kept in sync across presets (shipped v0.1.1)
- [x] Git-derived mode: version from the latest tag, build number from
      commit count (shipped v0.1.1)
- [x] Works as a plain action so any lane can compose it (bump → export →
      upload)

## v0.3.0 — Engine & template resolution

unity_exporter resolves the right Unity editor per-project via Unity Hub.
Godot has no Hub, but the project declares its version — use it.

- [x] Read the project's engine version from `project.godot`
      (`config/features`) and fail loudly when the resolved `godot` binary
      doesn't match, with guidance (shipped v0.1.2; `skip_version_check`
      overrides)
- [x] `godot_install_templates` — download the matching export-template
      archive and unpack only the platform needed (shipped v0.1.2;
      stable releases only, prereleases refused with guidance)
- [x] Binary discovery beyond `PATH`: common install locations + `GODOT`
      environment variable (shipped v0.1.2; version-manager hook deferred
      until a version manager is worth blessing)

## v0.4.0 — Android / Google Play

The other half of mobile. The export action is platform-agnostic already;
the knowledge and examples are not.

- [x] Verify `godot_export` against Android presets (Gradle builds, Android
      App Bundle output) — shipped v0.1.3: AAB verified on a real game via
      `install_android_build_template: true`
- [x] `examples/android-play/`: keystore setup, Play service-account key,
      `supply` upload to internal track (shipped v0.1.3; the upload lane is
      documented but unverified against a live Play app — needs a Play
      service account)
- [x] Sharp-edges table for the Android traps (shipped v0.1.3)
- [ ] Linux support verified — folded into the multi-version CI matrix
      (v0.5.0 scope): Linux runners exercise Android export there

## v0.5.0 — Continuous Integration templates

- [x] Reusable GitHub Actions workflows: `godot-ios-testflight.yml` and
      `godot-android-play.yml`, callable via `uses:` (shipped v0.1.4;
      documented in docs/CI.md, unverified against a live game repo until
      a game adopts them — Crunch is the natural first consumer)
- [x] Documented macOS-runner recipe for iOS in CI (docs/CI.md: setup_ci
      keychain, match-vs-get_certificates trade-off) (shipped v0.1.4)
- [x] Export smoke test in this repo's own CI (headless Web export of
      spec/fixtures/smoke_project on Linux via setup-godot) (shipped
      v0.1.4 — also the first Linux verification of godot_export)

## Quality bar (cross-cutting, every release)

- Dogfooded against a shipping game before tagging
- New export footguns get a diagnostic in the action *and* a row in the
  sharp-edges table
- Godot 4.2+ supported; each release names the versions actually tested

## Parity scorecard vs unity_exporter

| Capability | unity_exporter | Us today | Parity at |
| --- | --- | --- | --- |
| Headless export action | ✅ | ✅ | — |
| Failure diagnostics | ❌ | ✅ | ahead |
| No engine-side package required | ❌ (needs Unity package) | ✅ | ahead |
| Onboarding docs / example project | ❌ | ✅ | ahead |
| Signing & upload guidance | ❌ | ✅ | ahead |
| On RubyGems | ✅ | ❌ | v0.1.0 |
| Version/build-number management | ✅ | ❌ | v0.2.0 |
| Per-project engine resolution | ✅ (Unity Hub) | ⚠️ | v0.3.0 |
| Android verified + documented | ✅ | ⚠️ (verified; docs pending) | v0.4.0 |
| Years of production soak | ✅ (through ~2020) | ❌ | earned, not built |
