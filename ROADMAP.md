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
- [ ] Publish `fastlane-plugin-godot` to RubyGems
- [ ] Tag releases; start a CHANGELOG
- [ ] Switch README / example Pluginfile to the gem install
- [ ] Issue templates (bug report asks for Godot version, preset, full
      export output)

## v0.2.0 — Version & build-number management

unity_exporter's headline feature, and the piece our own pipeline wants
(versions derived from git tags, never hand-bumped).

- [ ] `godot_get_version` — read `application/short_version` /
      `application/version` from a preset
- [ ] `godot_set_version` — write them; semantic increments
      (`major`/`minor`/`patch`) and explicit values; keep iOS
      version/build and (later) Android version/code in sync across presets
- [ ] Git-derived mode: version from the latest tag, build number from
      commit count or a CI run number
- [ ] Works as a plain action so any lane can compose it (bump → export →
      upload)

## v0.3.0 — Engine & template resolution

unity_exporter resolves the right Unity editor per-project via Unity Hub.
Godot has no Hub, but the project declares its version — use it.

- [ ] Read the project's engine version from `project.godot`
      (`config/features`) and fail loudly when the resolved `godot` binary
      doesn't match, with guidance
- [ ] `godot_install_templates` — download the matching export-template
      archive and unpack only the platform needed (CI-friendly; the
      Chickensoft `setup-godot` action covers GitHub Actions, this covers
      everywhere else)
- [ ] Binary discovery beyond `PATH`: common install locations, an optional
      version-manager hook

## v0.4.0 — Android / Google Play

The other half of mobile. The export action is platform-agnostic already;
the knowledge and examples are not.

- [ ] Verify `godot_export` against Android presets (Gradle builds, Android
      App Bundle output)
- [ ] `examples/android-play/`: keystore setup, Play service-account key,
      `supply` upload to internal track
- [ ] Sharp-edges table for the Android traps (JDK/Gradle version
      alignment, target-API deadlines, texture-compression reimport)
- [ ] Linux support verified (Android exports don't need macOS)

## v0.5.0 — Continuous Integration templates

- [ ] Reusable GitHub Actions workflow: release-branch pushes → TestFlight
      / Play internal track (secrets: the three `ASC_*` values, keystore)
- [ ] Documented macOS-runner recipe for iOS in CI (certificate handling
      without fastlane match, and with it)
- [ ] Export smoke test in this repo's own CI (headless export of a
      fixture project via setup-godot) so engine upgrades can't silently
      break us

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
