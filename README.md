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

**Already using fastlane?** Install from git (RubyGems release coming):

```ruby
# fastlane/Pluginfile
gem 'fastlane-plugin-godot', git: 'https://github.com/Mad-Science-Software/fastlane-plugin-godot'
```

## Actions

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

- RubyGems release
- Android / Google Play example lane
- Continuous Integration (CI) workflow templates (GitHub Actions)
- Export-template installation action

## Development

```bash
bundle install
bundle exec rake   # runs the RSpec suite
```

Issues and pull requests welcome — especially reports of export footguns
this plugin doesn't yet catch.

## License

[MIT](LICENSE)
