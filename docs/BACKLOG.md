# Backlog

Findings that need plugin changes, newest first. Each entry says what
broke, where it belongs in the plugin, and what "done" looks like. When
one ships, move it to `CHANGELOG.md`.

## From the first real Android release export (2026-09-04, crunch)

Context: wiring a real game (crunch, in the mobile-portfolio repo) to
`godot-android-play.yml` and running `godot_export` on its
release-signed Android App Bundle (AAB) preset for the first time.

Shipped in 0.3.0 (see `CHANGELOG.md`): the runner editor-settings step
in `godot-android-play.yml`, the `.import` sidecar cleanup in
`godot_export`, and the documentation gaps (third-party plugin asset
directories, the single keystore password, `skip_upload_*` without a
metadata directory, `package_name` in the Appfile).

### 1. The version-code rule is copied into every Fastfile

Both of crunch's lanes shell out to `git rev-list --count HEAD` and call
`godot_set_version(build_number:)`. `from_git: true` already derives
the code from the commit count and the name from the tag.

**Done:** either document `from_git: true` as the recommended lane
shape for Play and TestFlight, or accept `build_number: 'commit_count'`
so lanes stop shelling out.

### 2. Small

- Cache Gradle in `godot-android-play.yml`; every run downloads the
  whole toolchain.
- `godot_init` could scaffold `fastlane/metadata` (and `package_name`
  in the Appfile) so the example lane's `skip_upload_*` flags become
  unnecessary.
