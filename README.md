# fastlane-plugin-godot

A [fastlane](https://fastlane.tools) plugin for shipping [Godot Engine](https://godotengine.org)
games to mobile app stores: headless exports with real diagnostics, wired into the
fastlane actions (`gym`, `pilot`, `supply`, …) that handle signing and store upload.

Early development. Not yet published to RubyGems — install from git:

```ruby
# fastlane/Pluginfile
gem 'fastlane-plugin-godot', git: 'https://github.com/Mad-Science-Software/fastlane-plugin-godot'
```

## Actions

### godot_export

Exports a Godot project headlessly using a named export preset from
`export_presets.cfg`. Verifies the preset exists, checks that the matching
engine version's export templates are installed for the preset's platform,
runs a resource import first (a stale import cache aborts Godot exports),
and confirms the artifact was actually produced — Godot has historically
exited 0 on some failed exports.

```ruby
lane :beta do
  xcodeproj = godot_export(
    project_path: '.',        # directory containing project.godot
    preset: 'iOS'             # preset name from export_presets.cfg
  )
  # For iOS presets the artifact is a generated Xcode project — hand it to gym:
  build_app(project: xcodeproj)
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

## Requirements

- Godot 4.x available on the `PATH` (or via `godot_binary`)
- The engine version's export templates installed for your target platform
- For iOS builds: macOS with Xcode

## Roadmap

- `godot_patch_xcodeproj` — declaratively re-apply capabilities and project
  settings after Godot regenerates the Xcode project on every export
- Export template download/installation action
- Android lane examples and Continuous Integration (CI) workflow templates

## Development

```bash
bundle install
bundle exec rake   # runs the RSpec suite
```

## License

[MIT](LICENSE)
