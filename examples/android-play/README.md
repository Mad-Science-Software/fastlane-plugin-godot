# Godot → Google Play, from zero

The Android sibling of the [iOS walkthrough](../ios-testflight/) — Godot 4
project to a Play internal-track upload. Read that one first for the shared
setup (Ruby, the plugin, `godot_init`); this covers what's Android-specific.

## 0. Prerequisites

- **Java Development Kit (JDK) 17** (Temurin recommended) and the
  **Android SDK** (install Android Studio once, or command-line tools).
- Tell Godot where they are: *Editor Settings → Export → Android* —
  `java_sdk_path` and `android_sdk_path` (these live in editor settings,
  not the project, so CI machines need them set too).
- **Android export templates** for your engine version:
  `bundle exec fastlane run godot_install_templates platform:Android`.
- A **Google Play Console** developer account ($25 one-time).

## 1. Two build shapes

- **APK, debug-signed** (`godot_export(preset: 'Android', debug: true)`) —
  for sideloading onto devices during development. Uses the auto-generated
  debug keystore; no setup.
- **Android App Bundle (AAB), release-signed** — what the Play Store
  ingests. Needs a Gradle build (Godot installs the build template into
  your project's `android/` directory during export — pass
  `install_android_build_template: true`, and add `android/` to your
  `.gitignore`) and a release keystore (next section).

## 2. Release keystore (one time)

```bash
keytool -genkeypair -v -keystore ~/keystores/upload.keystore \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

When `keytool` asks for a key password, reuse the store password: Godot's
release-signing configuration has a single password field, so a key whose
password differs from its store's cannot be used.

Godot reads release-signing configuration from environment variables in
Continuous Integration (CI) and headless use — put these in
`fastlane/.env` (gitignored; see the template):

```
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=~/keystores/upload.keystore
GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=...
```

With **Play App Signing** (default for new apps) this keystore is only the
*upload* key — Google holds the real signing key, and a lost upload key is
recoverable through Play Console support. Losing a pre-Play-App-Signing
key is not. Opt in.

## 3. Play Console service account (one time)

`upload_to_play_store` authenticates with a Google Cloud service-account
JSON key. The Play Console no longer has a "link a Cloud project" step
(older guides say *Setup → API access*; that page is gone), so:

1. In Google Cloud Console, in any project you own: **IAM & Admin →
   Service Accounts → Create**. Grant it no Cloud roles — it only needs
   Play permissions.
2. Same project: **APIs & Services → Enable APIs** → *Google Play Android
   Developer API*. Play used to enable this for a linked project; now it's
   manual.
3. Service account → **Keys → Add key → JSON**. Download it once and store
   it outside git. On an organisation created after 2024, Google's
   secure-by-default policy `iam.disableServiceAccountKeyCreation` blocks
   this: as an org admin, grant yourself *Organization Policy
   Administrator* at the organisation level, override that policy to *not
   enforced* on the one project, mint the key, then remove the override
   (existing keys keep working).
4. Play Console → **Users and permissions → Invite new users** → the
   service account's email (`…@…iam.gserviceaccount.com`) → *App
   permissions* → your app → **Release manager** (or the minimal pair:
   release to testing tracks + view app information). Service accounts
   accept automatically; permissions can take a few minutes to propagate.
5. `PLAY_JSON_KEY_PATH=...` in `fastlane/.env`, and `package_name` in
   `fastlane/Appfile` — `supply` reads the Android id from that key, not
   from `app_identifier`.

## 4. Ship

```bash
bundle exec fastlane android internal
```

Exports a release AAB (Gradle) and uploads it to the internal testing
track. See this example's `Fastfile`.

## Known sharp edges

| Symptom | Cause & answer |
| --- | --- |
| Export fails: "ETC2/ASTC texture compression is required for Android export" | Godot's message suggests an editor-GUI fix; headless, add `textures/vram_compression/import_etc2_astc=true` under `[rendering]` in `project.godot`. `godot_init` sets this for you since v0.2.1. |
| Your `.ipa`/APK quietly contains `vendor/bundle` (the fastlane gems!) | With bundler's `path vendor/bundle`, Godot imports the gem files and packs them into the game. Drop a `.gdignore` into `vendor/` and `.bundle/` — `godot_init` does since v0.2.1. |
| Gradle errors about Java versions | The JDK Godot uses must match what its Gradle template expects (JDK 17 for Godot 4.x). Set `java_sdk_path` in editor settings; don't rely on `JAVA_HOME`. |
| `Export: Building of Android project failed` with the real error buried | Godot hides Gradle's actual failure in the verbose output — re-run the lane with `verbose: true` and read from the bottom up. |
| AAB export fails asking for the build template | Gradle exports need the template installed in the project — pass `install_android_build_template: true` (the flag only works during an export). |
| Play rejects the upload over target API level | Google raises the required `targetSdkVersion` every year (August deadlines). Current Godot stable templates track it; being on an old engine patch release is the usual cause. |
| Textures silently uncompressed / bloated after enabling `import_etc2_astc` | Known engine bug: the setting doesn't reimport existing textures and the export dialog's "Fix Import" is broken (godot#94882). Delete `.godot/imported` and reimport. |
| `cannot connect to daemon at tcp:5037` during export | Harmless — Godot probing for a connected device via the Android Debug Bridge (adb). Not an export failure. |
| Play Console refuses the very first AAB from the API | The *first* upload for a new app must be done manually in the Play Console UI; the API works from the second one on. |
| Gradle: `…/android/build/res/…/*.import: The file name must end with .xml or .png` | Godot 4.7 installs the build template with no `.gdignore`, so an editor session or `--import` after the install sidecars the template's drawables (a `.gdignore` in `android/` does not survive the template install). `godot_export` removes them before every Android export since v0.3.0. |
| A third-party export plugin's assets fail the same way, or its notifications never post | Plugins that copy an assets directory into the Android project at export (e.g. `assets/NotificationSchedulerPlugin/android`) need that directory `.gdignore`d — the plugin copies it with `DirAccess`, Godot must not import it. Missing the directory entirely is worse: no small icon, so no notification can post. |
| Upload key rejected, or Godot asks for a password it never reads | Godot has one keystore password for release signing. Generate the upload key with `-keypass` equal to `-storepass` (the `keytool` line above does). |
