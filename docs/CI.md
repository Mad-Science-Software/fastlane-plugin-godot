# Continuous Integration (CI) for Godot mobile releases

Two reusable GitHub Actions workflows ship in this repository — call them
from a game repository with `uses:` (examples in each file's header):

- [`godot-ios-testflight.yml`](../.github/workflows/godot-ios-testflight.yml)
  — macOS runner → signed `.ipa` → TestFlight
- [`godot-android-play.yml`](../.github/workflows/godot-android-play.yml)
  — Linux runner → release Android App Bundle (AAB) → Play track

Both install the requested Godot version + export templates via
[chickensoft-games/setup-godot](https://github.com/chickensoft-games/setup-godot)
and then run one of your Fastfile's lanes, so your local lanes and CI stay
identical.

## iOS signing on a CI runner (read before the first run)

A fresh macOS runner has no keychain identities, which changes the signing
story compared to your laptop:

1. **Temporary keychain**: call fastlane's `setup_ci` at the top of your
   lane when running in CI (`setup_ci if ENV['CI']` — the examples in this
   repository do this). It creates an unlocked throwaway keychain so
   certificate import works headlessly.
2. **Certificates — use `match` for CI.** The laptop-friendly
   `get_certificates` flow *creates a new certificate* whenever the private
   key isn't present locally — on ephemeral runners that means a new
   certificate every run until you hit Apple's limit (2–3 distribution
   certificates per team). [fastlane match](https://docs.fastlane.tools/actions/match/)
   stores the certificate + key encrypted in a private git repository and
   imports them on each run; set `MATCH_PASSWORD` (and
   `MATCH_GIT_BASIC_AUTHORIZATION` for https checkout) as repository
   secrets — the iOS workflow passes them through.
   Solo-developer alternative: keep `get_certificates`, export the `.p12`
   from your laptop's Keychain Access, and import it in a pre-step —
   workable, but `match` ages better.
3. **App Store Connect API key**: store the `.p8` file's *contents* as the
   `ASC_KEY_CONTENT` secret; the workflow writes it to disk and exports
   `ASC_KEY_PATH` for your lane.
4. **Importing an existing identity into match? Export the `.p12` with
   Apple's tooling, not OpenSSL.** A `.p12` built by `openssl pkcs12
   -export` with an empty password fails on fresh CI keychains with
   `SecKeychainItemImport: MAC verification failed during PKCS12 import` —
   even though it imports fine on a Mac where the identity already exists
   (which is exactly how the bug hides until your first CI run). Use
   Keychain Access's export, or `security export -k login.keychain-db -t
   identities -f pkcs12`, and verify with a throwaway keychain:
   `security create-keychain -p x /tmp/t.db && security import your.p12
   -k /tmp/t.db -P ''`.
5. **Archive with manual signing on CI.** Godot's generated project
   defaults to automatic signing, which needs a development identity and
   an Xcode account session — neither exists on a runner. Point the archive
   at what match installed instead:
   `xcargs: 'CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Apple Distribution"
   DEVELOPMENT_TEAM=<team> PROVISIONING_PROFILE_SPECIFIER="<match profile>"'`
   (the profile name comes from match's provisioning-profile mapping in the
   lane context). This also supersedes the godot#110052 workaround.

## Android on a CI runner

Linux runners work (no macOS needed): the workflow installs Temurin JDK 17,
the Android SDK is preinstalled on GitHub's Ubuntu images, and Godot reads
release-keystore credentials from the `GODOT_ANDROID_KEYSTORE_RELEASE_*`
environment variables — fed from secrets, with the keystore itself stored
base64-encoded in `KEYSTORE_BASE64`.

One Godot-specific wrinkle: Godot needs `java_sdk_path` and
`android_sdk_path` in its *editor settings* on the runner. The first
Gradle export will fail without them; add a pre-step writing
`~/.config/godot/editor_settings-4.<minor>.tres` if you hit it (and open an
issue — making the plugin handle this is on the roadmap).

## The plugin's own smoke test — a Godot version matrix

This repository's CI runs a headless Web export of
`spec/fixtures/smoke_project` on every push, across a matrix of Godot
versions (currently 4.2.2 through 4.7.1, Linux runners) — proving the
export path end to end against real engine downloads. The README's
supported-version claim comes from this matrix, not hand-testing.

For a quick local check against any engine version without installing it,
the [godot-ci Docker images](https://github.com/abarichello/godot-ci)
bundle the engine and its export templates:

```bash
docker run --rm -v "$PWD/spec/fixtures/smoke_project:/project" \
  barichello/godot-ci:4.2.2 sh -c \
  "mkdir -p /project/build/web && godot --headless --path /project \
   --export-release Web /project/build/web/index.html"
```

(On Apple Silicon the images run under amd64 emulation — slower, works.)
