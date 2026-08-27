# Godot → TestFlight from CI (no Mac required)

Ship an iOS build of your Godot game to TestFlight from a GitHub Actions
macOS runner — your own machine can run Linux or Windows; the runner does
everything a Mac would. This is the continuous-integration companion to
the [local iOS walkthrough](../ios-testflight/); do that setup first
(project prep, App Store Connect API key, app record), then add this.

What you'll end up with: push-button (or push-triggered) builds where the
runner installs Godot, exports your project, signs it with certificates
pulled from an encrypted git repository, and uploads to TestFlight —
verified end to end (a real game shipped this way the day this was
written; ~6 minutes per run).

## 1. A certificates repository (one time)

[fastlane match](https://docs.fastlane.tools/actions/match/) keeps your
signing certificate and provisioning profile encrypted in a private git
repository so ephemeral runners can sign without your keychain.

```bash
gh repo create your-org/certificates --private
```

Add a `fastlane/Matchfile` next to your Fastfile:

```ruby
git_url('https://github.com/your-org/certificates.git')
storage_mode('git')
type('appstore')
app_identifier(['com.yourstudio.yourgame'])
team_id('YOURTEAMID')
readonly(true)
```

Pick a strong `MATCH_PASSWORD` (this encrypts everything in the repo —
store it in your password manager), then populate the repo. Two cases:

- **No distribution certificate yet** (most common): let match create
  everything —
  `MATCH_PASSWORD=... bundle exec fastlane match appstore --readonly false`
- **Existing certificate**: import it — but export the `.p12` with
  Apple's own tooling (Keychain Access, or `security export`), *not*
  `openssl`; see the [p12 sharp edge in docs/CI.md](../../docs/CI.md).

## 2. Runner access to the certificates repo (one time)

A read-only deploy key lets CI clone the certificates repo without a
personal token:

```bash
ssh-keygen -t ed25519 -N '' -C 'ci-match-readonly' -f match_deploy_key
gh api repos/your-org/certificates/keys \
  -f title='game CI (read-only)' -f key="$(cat match_deploy_key.pub)" -F read_only=true
```

## 3. Repository secrets (one time)

On your game repository:

```bash
gh secret set ASC_KEY_ID --body 'ABC123DEFG'
gh secret set ASC_ISSUER_ID --body '12345678-1234-1234-1234-123456789012'
gh secret set ASC_KEY_CONTENT < AuthKey_ABC123DEFG.p8
gh secret set MATCH_PASSWORD --body '<your match passphrase>'
gh secret set MATCH_GIT_PRIVATE_KEY < match_deploy_key
```

Delete the local `match_deploy_key` files afterwards.

## 4. The lane (CI-safe signing)

On a runner there is no development identity and no Xcode account, so the
archive must use **manual signing with exactly what match installed** —
see this directory's [`Fastfile`](fastlane/Fastfile). The differences from
the local-walkthrough lane: `match(type: 'appstore', readonly: true)`
replaces `get_certificates`/`get_provisioning_profile`, and the `xcargs`
pin `CODE_SIGN_STYLE=Manual` with the match profile. This lane works
identically on your machine and in CI.

## 5. The workflow

Copy [`godot-ios-beta.yml`](godot-ios-beta.yml) to your game repository's
`.github/workflows/`, adjust the inputs, push, and run it from the
Actions tab (or change the trigger to fire on a release branch). It calls
this plugin's reusable
[`godot-ios-testflight.yml`](../../.github/workflows/godot-ios-testflight.yml),
which installs Ruby, Godot + export templates, writes the API key, and
runs your lane.

## Notes

- macOS runners are free on public repositories; private repositories
  bill them at a 10× minute multiplier (a typical run here is ~6 minutes).
- The Apple Developer Program ($99/year) is required regardless, and
  TestFlight needs an Apple device to test on.
- Give each upload a fresh build number or TestFlight rejects it —
  `godot_set_version(build_number: 'increment')` or
  `godot_set_version(from_git: true)` in the lane automates this.
- First-run failures are almost always one of the sharp edges in
  [docs/CI.md](../../docs/CI.md) — the p12 format and manual-signing
  entries exist because we hit them.
