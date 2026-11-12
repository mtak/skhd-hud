# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [0.1.1] - 2026-11-12

### Fixed

- App icons for apps installed as symlinks (such as Safari on recent macOS) no
  longer show an alias arrow badge.

### Added

- Screenshot in the README.

## [0.1.0] - 2026-11-12

### Added

- On-screen HUD message for skhd hotkeys, shown on the screen under the mouse
  cursor, about one third down from the top. It does not take focus or
  intercept clicks.
- Pop-in and fade-out animation, dark background with accent-colored border.
- `-a`, `--app`: show an app's icon, by app name or bundle id.
- `-d`, `--duration`: time on screen in seconds (default 1.2).
- `-c`, `--color`: border color by name or hex.
- `-v`, `--version` and `-h`, `--help`.
- Messages longer than 256 characters are truncated; long text wraps.
- GitHub Actions workflow that builds a universal (arm64 + x86_64) binary and
  publishes it as a GitHub release on version tags.

[0.1.1]: https://github.com/mtak/skhd-hud/releases/tag/v0.1.1
[0.1.0]: https://github.com/mtak/skhd-hud/releases/tag/v0.1.0
