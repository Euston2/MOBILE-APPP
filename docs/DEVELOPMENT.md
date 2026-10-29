# Development workflow

## Branch model

```
main      ← release tags only (always green, always tagged)
  ↑ merge (release)
develop   ← integration branch, PR target for features
  ↑ PR (CI green)
feature/<name>
```

Never commit directly to `main` or `develop`. Branch protection for `main`
should require the `CI / Analyze & test` and `CI / Build debug APK` checks plus
one review.

## Day-to-day loop

```bash
git switch develop
git pull
git switch -c feature/short-name

# ... work, commit in small Conventional Commits ...
git commit -m "feat(home): add circular progress ring"

# always: format, analyze, test before pushing
dart format lib test
flutter analyze --fatal-infos
flutter test
flutter build apk --debug

git push -u origin feature/short-name
```

Open a PR into `develop` using the template. Squash-merge once CI is green.

## Definition of done for a change

1. Code follows the layering rules in `docs/ARCHITECTURE.md`.
2. New risky logic has unit tests (time windows, lock, reset).
3. `dart format`, `flutter analyze --fatal-infos`, `flutter test` pass locally.
4. APK builds (`flutter build apk --debug`).
5. `pubspec.yaml` version bumped according to semver.
6. `CHANGELOG.md` updated under `## [Unreleased]` (moved to a version heading on
   release).
7. PR merged into `develop`; `main` fast-forwards only for a release.

## Commit convention

`<type>(<scope>): <summary>` — types: `feat`, `fix`, `chore`, `docs`,
`refactor`, `test`, `perf`, `ci`, `build`.

Examples:

```
feat(tracking): read today's usage from UsageStatsManager
fix(blocking): re-launch block screen when user presses Back
docs(permissions): explain exact alarm fallback
chore(deps): bump drift to 2.28.0
```

## Versioning

| Change | Bump |
| ------ | ---- |
| Breaking behaviour / data migration | MAJOR |
| New user-facing capability | MINOR |
| Fix, docs, internal polish | PATCH |

Stages map to: `0.0.1 → 0.1.0 → 0.2.0 → 0.3.0 → 0.4.0 → 0.5.0 → 0.6.0 → 1.0.0`.

## Release

See [`RELEASING.md`](RELEASING.md).

## Local environment notes (this machine)

Flutter is not on `PATH`; use `C:\src\flutter\bin\flutter.bat` (or add
`C:\src\flutter\bin` to `PATH`). Android SDK lives at
`%LOCALAPPDATA%\Android\Sdk`. Use Android Studio's bundled JDK 21 for Gradle.

The project lives under a OneDrive-synced folder. If Gradle ever fails with
file-lock errors, pause OneDrive sync for the project folder or clone the repo
to a local path such as `C:\dev\lockout`.
