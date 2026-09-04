# Backlog

Findings that need plugin changes, newest first. Each entry says what
broke, where it belongs in the plugin, and what "done" looks like. When
one ships, move it to `CHANGELOG.md`.

## From the first real Android release export (2026-09-04, crunch)

Context: wiring a real game (crunch, in the mobile-portfolio repo) to
`godot-android-play.yml` and running `godot_export` on its
release-signed Android App Bundle (AAB) preset for the first time.

### 1. The reusable Android workflow never configures Godot's editor settings — blocks the first CI upload

Godot reads `export/android/java_sdk_path` and `android_sdk_path` from
its *editor settings file*, not from `JAVA_HOME` / `ANDROID_HOME`. The
plugin's own `test.yml` Android smoke job writes that file; the
reusable `godot-android-play.yml` does not, so a caller's first Gradle
export on an Ubuntu runner fails. `docs/CI.md` already tells callers to
add a pre-step by hand.

**Done:** a step in `godot-android-play.yml` that writes
`~/.config/godot/editor_settings-4.<minor>.tres` (minor derived from
the `godot-version` input) with `java_sdk_path` and `android_sdk_path`
from the runner's environment, and the `docs/CI.md` wrinkle paragraph
rewritten to say the workflow handles it.

### 2. `godot_export` should delete `.import` sidecars under `android/build/res`

Godot 4.7 installs the Android build template with no `.gdignore` in
`android/`, and `--install-android-build-template` wipes `android/`
wholesale, so a `.gdignore` placed there does not survive. Any editor
session or `--import` afterwards (including the `import_first` pass
`godot_export` runs by default) writes `*.import` sidecars next to the
template's drawables, and Gradle's resource merger fails with
`The file name must end with .xml or .png`.

Only `res/` is affected. The export itself legitimately packs the
game's own sidecars into the asset-pack directories.

**Done:** `godot_export` removes `android/build/res/**/*.import` under
the project path before exporting (after `import_first`), and the
sharp-edge row in `examples/android-play/README.md` points at the
plugin version that does it. Crunch's Fastfile carries the workaround
by hand until then.

### 3. Documentation gaps

- **Third-party export plugins copy asset directories into the Android
  project.** The notification-scheduler plugin copies
  `assets/<Plugin>/android` into Gradle's resource tree at export. That
  directory must be `.gdignore`d or Godot's sidecars ride along and
  trip the same resource-merger error as item 2. Add to the sharp-edge
  table (done in this change).
- **Godot has one keystore password.** The release-signing config has
  no separate key password, so an upload key generated with a
  `-keypass` different from `-storepass` cannot be used. The example's
  `keytool` line already generates a matching pair; say why.
- **`upload_to_play_store` expects `fastlane/metadata`.** Without that
  directory it errors unless `skip_upload_metadata`, `_changelogs`,
  `_images` and `_screenshots` are passed. The example lane passes
  none of them; either add the flags or ship the metadata scaffold
  from `godot_init`.

### 4. The version-code rule is copied into every Fastfile

Both of crunch's lanes shell out to `git rev-list --count HEAD` and call
`godot_set_version(build_number:)`. `from_git: true` already derives
the code from the commit count and the name from the tag.

**Done:** either document `from_git: true` as the recommended lane
shape for Play and TestFlight, or accept `build_number: 'commit_count'`
so lanes stop shelling out.

### 5. Small

- Cache Gradle in `godot-android-play.yml`; every run downloads the
  whole toolchain.
- `godot_init` writes `.gdignore` for `build/`, `vendor/` and
  `.bundle/`; the Android template cannot be handled the same way (see
  item 2), so this stays an action-side fix.
