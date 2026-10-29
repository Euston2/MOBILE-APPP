# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Stage 1: permission flow, `UsageStatsManager` tracking, installed-app picker.

## [0.0.1] - 2026-10-29

### Added

- Flutter project (`lockout`) with Android-only target, Material 3 theme and a
  Riverpod `ProviderScope` at the root.
- Clean-architecture folder skeleton: `core`, `domain`, `data`, `platform` and
  `features/{onboarding,home,limits,blocking,history}`.
- Kotlin package layout (`com.lockout.lockout`) with a dedicated `platform`
  package for the future channels, services and receivers.
- GitHub Actions `ci.yml` (format, analyze, test, debug APK, gated Kotlin unit
  tests) and `release.yml` (signed APK on `v*` tags).
- Issue templates (bug, feature) and a pull-request template.
- `README.md`, `CHANGELOG.md`, `LICENSE`, architecture/permissions/workflow docs.
- Release signing plumbing in Gradle via git-ignored `android/key.properties`.
- Widget tests for app boot and small-screen layout.

[Unreleased]: https://github.com/Euston2/MOBILE-APPP/compare/v0.0.1...develop
[0.0.1]: https://github.com/Euston2/MOBILE-APPP/releases/tag/v0.0.1
