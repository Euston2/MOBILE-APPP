# Releasing

Releases are tag-driven. Pushing a tag that matches `vX.Y.Z` triggers
`.github/workflows/release.yml`, which builds a release APK and publishes a
GitHub Release with auto-generated notes and the APK attached.

## Current status: friends-and-family preview

Lockout 1.2.0 is currently a **friends-and-family preview**, not a Play Store
release. It is built from `develop`, updates over a previous build only if the
signing key matches, and is meant for feedback on real phones.

Without `android/key.properties`, Gradle falls back to the local debug key. That
is acceptable for a private preview but **not** for public distribution. The
preview is intentionally not tagged until:

- release signing secrets are configured;
- the device matrix in [`TESTING.md`](TESTING.md) has been run on the target
  phones; and
- the feedback round is complete.

### Build and verify the preview

```powershell
C:\src\flutter\bin\flutter.bat build apk --release
Copy-Item build\app\outputs\flutter-apk\app-release.apk `
  build\app\outputs\flutter-apk\lockout-1.2.0-preview.apk
```

Verify the APK, its version, its signature, and that the SQLite native library
was packaged:

```powershell
$sdk = "$env:LOCALAPPDATA\Android\sdk"
$buildTools = Get-ChildItem "$sdk\build-tools" | Sort-Object Name | Select-Object -Last 1
$apk = "build\app\outputs\flutter-apk\lockout-1.2.0-preview.apk"
& "$($buildTools.FullName)\apksigner.bat" verify --verbose --print-certs $apk
& "$($buildTools.FullName)\aapt.exe" dump badging $apk |
  Select-String "package:|application-label"
tar -tf $apk | Select-String "lib/arm64-v8a/libsqlite3.so"
```

The last command must print `lib/arm64-v8a/libsqlite3.so`. A missing library
causes History and Limit & apps to fail on the phone. `CN=Android Debug` in the
certificate output means the APK is debug-signed.

`sqlite3_flutter_libs` is pinned to `0.5.42` while the app uses drift 2.30 and
sqlite3 2.x. Do not move it to `0.6.0+eol`; that release is an empty migration
stub with no native libraries.
Install it with `adb install -r <apk>` or by transferring the file and allowing
"install unknown apps" for the file manager.

### Sideload notes for testers

- Grant usage access, overlay, notifications and battery exemption during
  onboarding; the in-app **Protection check** shows what is missing.
- Follow the OEM battery/autostart steps for the phone. A user force-stop still
  disables alarms and the watcher until Lockout is opened again.
- The app has no account or cloud sync. History and diagnostics stay local.
- Report the phone model, Android version, what happened, and the copied
  diagnostics report from Protection check.

## Public release signing

Do this once, before tagging a public release.

1. Create a keystore (keep it out of the repo and back it up):

   ```bash
   keytool -genkeypair -v -keystore lockout-release.jks \
     -alias lockout -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Base64-encode it:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("lockout-release.jks")) > keystore.b64
   ```

3. Add repository secrets (Settings → Secrets and variables → Actions):

   | Secret | Value |
   | ------ | ----- |
   | `ANDROID_KEYSTORE_BASE64` | contents of `keystore.b64` |
   | `ANDROID_KEYSTORE_PASSWORD` | store password |
   | `ANDROID_KEY_ALIAS` | `lockout` |
   | `ANDROID_KEY_PASSWORD` | key password |

   With the GitHub CLI:

   ```bash
   gh secret set ANDROID_KEYSTORE_BASE64 < keystore.b64
   gh secret set ANDROID_KEYSTORE_PASSWORD
   gh secret set ANDROID_KEY_ALIAS
   gh secret set ANDROID_KEY_PASSWORD
   ```

4. For local release builds, create `android/key.properties` (git-ignored):

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=lockout
   storeFile=release-keystore.jks
   ```

   Place `release-keystore.jks` in `android/app/`.

Until the secrets are configured, `release.yml` still builds and publishes an
APK, but signs it with the debug key, emits a warning, and records the
certificate in the workflow log. Do not call that a public release.

## Release checklist

```bash
git switch develop
git pull
# 1. bump pubspec.yaml version and AppConstants.appVersion
# 2. move CHANGELOG "Unreleased" notes under the version heading
# 3. update README version/status
git commit -am "chore(release): 1.2.0"
git push

git switch main
git pull
git merge --ff-only develop
git push

git tag -a v1.2.0 -m "Lockout v1.2.0"
git push origin v1.2.0
```

Before tagging, run the full gate:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
cd android && ./gradlew :app:testDebugUnitTest
cd .. && flutter build apk --release
```

Then verify:

- CI is green on the tag commit.
- The Release workflow produced the APK and the signature check passed.
- `apksigner verify` reports the release certificate, not `CN=Android Debug`,
  for a public build.
- `CHANGELOG.md` links for the new version resolve.
- The device matrix has a recorded result for at least one target OEM.
