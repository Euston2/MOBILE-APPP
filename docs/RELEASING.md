# Releasing

Releases are tag-driven. Pushing a tag that matches `vX.Y.Z` triggers
`.github/workflows/release.yml`, which builds a signed APK and publishes a
GitHub Release with auto-generated notes and the APK attached.

## One-time signing setup

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

   and place `release-keystore.jks` in `android/app/`.

## Release checklist

```bash
git switch develop
git pull
# 1. bump version in pubspec.yaml (e.g. 0.2.0+1 -> 0.3.0+1)
# 2. move CHANGELOG "Unreleased" notes under "## [0.3.0] - YYYY-MM-DD"
git commit -am "chore(release): 0.3.0"
git push

git switch main
git pull
git merge --ff-only develop
git push

git tag -a v0.3.0 -m "Lockout v0.3.0"
git push origin v0.3.0
```

Then verify:

- CI is green on the tag commit.
- The Release workflow produced a signed APK (check `apksigner verify`).
- `CHANGELOG.md` links for the new version resolve.
