# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Stage 2: drift database, monitored-app selection, daily limit, progress ring.

## [0.1.0] - 2026-10-29

### Added

- Permission onboarding with live status for usage access, overlay,
  notifications and battery-optimisation exemption, each deep-linking to its
  system screen and re-checked when the app resumes.
- Native usage tracking over `UsageStatsManager.queryEvents`: foreground
  resume/pause/lock events are clipped to local midnight by a pure
  `UsageAggregator`, so numbers match "since 00:00" rather than a drifting
  daily bucket.
- Installed-app catalogue (`PackageManager` + `QUERY_ALL_PACKAGES`) with
  labels and a system flag, excluding Lockout itself.
- Home screen with today's combined time, per-app breakdown with bars, manual
  pull-to-refresh and a five-second poll while visible.
- Single Kotlin `LockoutPlatform` MethodChannel (`getPermissionStatus`,
  settings intents, `getInstalledApps`, `getUsageSince`) with async work off
  the main thread.
- Dart domain layer: `UsageRepository`, `PermissionsRepository`,
  `summarizeUsage`, `startOfLocalDay`/`nextLocalMidnight`, duration formatting.
- Tests: 9 JVM tests for `UsageAggregator`, plus Dart unit tests for the time
  window, aggregation and formatting, and widget tests for onboarding and Home.
- Manifest permissions for usage access, package visibility, overlay,
  notifications and battery-optimisation exemption, each documented inline.

## [0.0.1] - 2026-10-29

### Added

- Flutter project (`lockout`) with Android-only target, Material 3 theme and a
  Riverpod `ProviderScope` at the root.
- Clean-architecture folder skeleton: `core`, `domain`, `data`, `platform` and
  `features/{onboarding,home,limits,blocking,history}`.
- Kotlin package layout (`com.lockout.lockout`) with a dedicated `platform`
  package for the future channels, services and receivers.
- GitHub Actions `ci.yml` (format, analyze, test, debug APK, gated Kotlin unit
  tests) and `release.yml` (signed APK on `v*` tags, debug-signed with a warning
  until the keystore secrets exist).
- Issue templates (bug, feature) and a pull-request template.
- `README.md`, `CHANGELOG.md`, `LICENSE`, architecture/permissions/workflow docs.
- Release signing plumbing in Gradle via git-ignored `android/key.properties`.
- Widget tests for app boot and small-screen layout.

[Unreleased]: https://github.com/Euston2/MOBILE-APPP/compare/v0.1.0...develop
[0.1.0]: https://github.com/Euston2/MOBILE-APPP/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/Euston2/MOBILE-APPP/releases/tag/v0.0.1
