# fastlane-plugin-godot

A [fastlane](https://fastlane.tools) plugin for shipping [Godot Engine](https://godotengine.org)
games to mobile app stores: headless exports with real diagnostics, composing
with the fastlane actions (`gym`, `pilot`, `cert`, `sigh`, `supply`, …) that
already handle signing and store upload.

**New to fastlane?** Start with the
[Godot → TestFlight from-zero walkthrough](examples/ios-testflight/) — a
complete copy-paste setup including Ruby installation, the App Store Connect
API key, Godot project prep, and a working Fastfile. First setup ~30 minutes;
~4 minutes per release after that.

**Already using fastlane?**

```bash
fastlane add_plugin godot
```

## Actions

### godot_init

Scaffolds everything a Godot project needs for mobile releases — run once
from the project directory:

```bash
bundle exec fastlane run godot_init
```

Creates (only when missing — existing files are never touched): `Gemfile`,
`fastlane/{Pluginfile,Appfile,Fastfile,.env.template}`, an
`export_presets.cfg` with iOS + Android presets, `build/.gdignore` (so Godot
doesn't import its own build products), a placeholder 1024×1024 `app_icon.png`
(iOS export hard-fails without an icon; pass `icon:false` to skip), and a
`.gitignore` (or a warning listing entries yours is missing). Finishes by
listing the placeholders you must fill in: bundle identifier, team ID, and
your App Store Connect API key in `fastlane/.env`.

### godot_get_version / godot_set_version

Read and write the version name + build number in `export_presets.cfg`,
keeping iOS (`short_version`/`version`) and Android (`version/name`/
`version/code`) in sync across every preset:

```ruby
godot_set_version(version: 'patch', build_number: 'increment')
godot_set_version(from_git: true)   # version from latest tag, build from commit count
godot_get_version                    # => { version_name: '1.2.0', version_code: 42 }
```

### godot_export

Exports a Godot project headlessly using a named export preset from
`export_presets.cfg`, wrapping every footgun we have personally hit shipping
a real game with it:

- verifies the preset exists (and lists the available ones when it doesn't)
- verifies the matching engine version's export templates are installed for
  the preset's platform, with download guidance when they aren't
- runs a headless `--import` first — a stale import cache aborts Godot
  exports with a crash-lookalike exit 134
- creates the output directory (Godot errors rather than create it)
- confirms the artifact was actually produced — Godot has historically
  exited 0 on some failed exports

```ruby
lane :beta do
  xcodeproj = godot_export(preset: 'iOS')
  build_app(project: xcodeproj, scheme: File.basename(xcodeproj, '.xcodeproj'))
  upload_to_testflight
end
```

| Option | Description | Default |
| --- | --- | --- |
| `preset` | Export preset name (required) | — |
| `project_path` | Directory containing `project.godot` | `.` |
| `godot_binary` | Path to the Godot binary | `godot` |
| `output_path` | Artifact destination, relative to the project | the preset's `export_path` |
| `debug` | Export a debug build | `false` |
| `import_first` | Run headless `--import` before exporting | `true` |
| `verbose` | Pass `--verbose` to Godot | `false` |

Every option is also settable via environment variable (`FL_GODOT_*`).
Returns the absolute artifact path (for iOS presets, the generated Xcode
project) and sets `lane_context[:GODOT_EXPORT_OUTPUT]`.

`godot_export` also resolves and sanity-checks the engine: when `godot`
isn't on the `PATH` it looks in common install locations and the `GODOT`
environment variable, and it refuses to export when the binary's version
doesn't match the engine version the project declares in
`config/features` (cross-version exports corrupt import caches) —
`skip_version_check: true` overrides.

### godot_install_templates

Downloads and installs the export templates matching your Godot binary's
version — one platform's worth or everything:

```ruby
godot_install_templates(platform: 'iOS')   # or Android, macOS, Web, all
```

Skips work when the templates are already present, so it's safe to leave
at the top of a lane as a CI bootstrap.

## The iOS signing story (read this once)

Godot generates a fresh Xcode project on every export, with two properties
that break naive pipelines:

1. **It writes `CODE_SIGN_IDENTITY="Apple Distribution"` into an
   automatic-signing configuration**
   ([godot#110052](https://github.com/godotengine/godot/issues/110052)),
   which xcodebuild rejects as conflicting. Fix: archive with
   `xcargs: 'CODE_SIGN_IDENTITY="Apple Development"'` and let the export
   step re-sign for distribution.
2. **xcodebuild's cloud signing requires an Admin App Store Connect API
   key** (`Cloud signing permission error` otherwise). You don't need it:
   fastlane's stock `get_certificates` + `get_provisioning_profile` do
   classic signing with an App Manager key, idempotently.

The [example Fastfile](examples/ios-testflight/fastlane/Fastfile) wires both
correctly. Its
[README's sharp-edges table](examples/ios-testflight/README.md#known-sharp-edges-and-how-this-setup-dodges-them)
maps the exact error messages to fixes.

## Requirements

- Godot 4.x available on the `PATH` (or via `godot_binary`)
- The engine version's export templates installed for your target platform
- For iOS builds: macOS with Xcode

## Roadmap

See [ROADMAP.md](ROADMAP.md) — next up: RubyGems release, version/build-number
management actions, engine-version resolution, Android/Google Play, and
Continuous Integration (CI) workflow templates.

## Development

```bash
bundle install
bundle exec rake   # runs the RSpec suite
```

Issues and pull requests welcome — especially reports of export footguns
this plugin doesn't yet catch.

## License

[MIT](LICENSE)
