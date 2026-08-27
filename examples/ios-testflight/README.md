# Godot → TestFlight, from zero

A complete, copy-paste setup that takes a Godot 4 mobile game from
`project.godot` to a build on TestFlight with one command — including the
case where you have never touched fastlane or Ruby before.

Time budget: ~30 minutes the first time, ~4 minutes per release after.

## 0. Prerequisites

- **macOS with Xcode** installed (iOS builds require both).
- **Godot 4.x** available on your `PATH` as `godot` (or note its path for
  later). Verify: `godot --version`.
- **Godot iOS export templates** for that exact version: open Godot once and
  use *Editor → Manage Export Templates*, or download the `.tpz` from
  [godotengine.org/download](https://godotengine.org/download) and unzip
  `ios.zip` into
  `~/Library/Application Support/Godot/export_templates/<version>/`.
- A **paid Apple Developer Program membership**.
- **Ruby 3.1+**. macOS system Ruby is too old; get a current one with
  [Homebrew](https://brew.sh): `brew install ruby`, then add what
  `brew info ruby` tells you to your `PATH`.

## 1. An App Store Connect API key (one time)

This key replaces Apple ID logins and Two-Factor Authentication (2FA)
prompts everywhere — signing, provisioning, and upload — and works in
Continuous Integration (CI).

1. Sign in at [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   → **Users and Access** → **Integrations** → **App Store Connect API** →
   **Team Keys**.
2. Generate a key with the **App Manager** role.
3. Copy the **Issuer ID** — it is the small line *above* the keys table,
   not in the table.
4. Copy the key's **Key ID** and download the `.p8` file (offered once).
   Store it outside any git repository, e.g. `~/.appstoreconnect/`.

Then copy `fastlane/.env.template` to `fastlane/.env` and fill in the three
values — fastlane loads `.env` automatically on every run, so nothing needs
exporting by hand. Add `fastlane/.env` to your `.gitignore`; commit only the
template. (In CI, set the same three variables as repository secrets
instead.)

## 2. Prepare the Godot project (one time)

Four things iOS export requires that a desktop-focused project may lack:

1. **An app icon.** iOS export hard-fails without one
   (`ERROR: Export Icons: Invalid icon`). Add a 1024×1024 PNG **without an
   alpha channel** and reference it in the preset below.
2. **An export preset.** Create it in the editor (*Project → Export → Add →
   iOS*) or commit `export_presets.cfg` directly. The essentials:
   - `application/bundle_identifier` — permanent once shipped; pick well.
   - `application/app_store_team_id` — your 10-character Apple team ID.
     Careful if you belong to several teams: check
     *Xcode → Settings → Accounts*, and prefer the team your other apps
     ship under.
   - `application/export_project_only=true` — export the Xcode project and
     let fastlane build it (this example's flow).
   - `application/short_version` / `application/version` — TestFlight
     rejects empty versions.
3. **A `.gdignore` in your build-output directory** (`build/.gdignore` if
   you export to `build/`). Without it Godot imports its own build
   products — and packs previous exports into the next one.
4. **Exclude test/dev addons from the export** so they don't ship:
   `exclude_filter="addons/gdUnit4/*, test/*"` (adjust to taste).

## 3. Install fastlane + this plugin (one time)

From your game project's directory, copy this example's `Gemfile` and
`fastlane/` directory (`Fastfile`, `Appfile`, `Pluginfile`), edit the
`Appfile` values, then:

```bash
bundle install
```

That is the entire fastlane installation — `bundle` reads the `Gemfile`,
installs fastlane and this plugin, done.

## 4. Register the app (one time)

```bash
bundle exec fastlane produce -i          # registers the bundle ID
```

Then create the app record itself at App Store Connect → **Apps** → **⊕ New
App** (Apple's public API cannot create app records, so this single step is
manual — two minutes, once per app).

## 5. Ship

```bash
bundle exec fastlane ios beta
```

What happens, in order: `godot_export` runs a headless export with
diagnostics (missing template, bad preset name, stale import cache, and
silent-failure detection are all handled); `get_certificates` and
`get_provisioning_profile` reuse or create your Apple Distribution
certificate and App Store profile via the API key; `build_app` archives and
signs; `upload_to_testflight` uploads. First run mints certificates and
takes longer; after that the loop is ~4 minutes.

First-time-only afterwards: in App Store Connect → your app → TestFlight,
add yourself to an internal group, and accept the emailed invite —
TestFlight (the phone app) only lists an app *after* its invite is accepted.

## Known sharp edges (and how this setup dodges them)

| Symptom | Cause & answer |
| --- | --- |
| `conflicting provisioning settings … Apple Distribution has been manually specified` | Godot writes a distribution identity into an automatic-signing config ([godot#110052](https://github.com/godotengine/godot/issues/110052)). The Fastfile's `CODE_SIGN_IDENTITY="Apple Development"` xcargs override fixes it at archive time. |
| `Cloud signing permission error` | xcodebuild's *cloud signing* wants an Admin API key. This setup avoids cloud signing entirely: `get_certificates`/`get_provisioning_profile` do classic signing with an App Manager key. |
| `Export Icons: Invalid icon` | No icon in the preset/project. See step 2. |
| Exports abort with exit 134 after adding scripts | Stale import cache. `godot_export` runs `--import` first by default. |
| Previous builds bloat every new export | Missing `.gdignore` in the output directory. See step 2. |
| Uploaded build never appears for testers | Check the build's export-compliance question in App Store Connect, and remember invites must be accepted once per app. |
| Post-upload email: `ITMS-90068: MinimumOSVersion too low` | Apple raises the floor over time (iOS 15.0 required from Spring 2027). Set `application/min_ios_version` in the export preset to at least the current requirement. |
