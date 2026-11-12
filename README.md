# skhd-hud

A tiny macOS heads-up display for [skhd](https://github.com/koekeishiya/skhd) hotkeys.
It flashes a short message (optionally with an app icon) on the screen under your
mouse cursor, then fades out. It never steals focus or intercepts clicks.

![skhd-hud showing "Switched to Safari" with the Safari icon](docs/screenshot.png)

Typical uses: confirm an app switch, a window-manager action, or a mode change.

## Install

### Prebuilt binary

Download `skhd-hud-macos-universal.zip` from the
[latest release](https://github.com/mtak/skhd-hud/releases/latest)
(universal: Apple Silicon and Intel, macOS 12+):

```sh
unzip skhd-hud-macos-universal.zip
xattr -d com.apple.quarantine skhd-hud   # binary is unsigned (ad-hoc)
mv skhd-hud /usr/local/bin/
```

### Build from source

Requires the Xcode Command Line Tools.

```sh
swiftc -O skhd-hud.swift -o skhd-hud
```

You can also run the script directly (`./skhd-hud.swift "hello"`), but it is
compiled on every run and takes ~0.7s to appear — use the binary for hotkeys.

## Usage

```
skhd-hud [-d seconds] [-c color] [-a app] [--] message...
```

| Option | Description |
|---|---|
| `-d`, `--duration` | Seconds on screen (default `1.2`). |
| `-c`, `--color` | Border color: `accent` (default, system accent color), `red`, `orange`, `yellow`, `green`, `blue`, `purple`, `pink`, `gray`, `white`, or hex like `#ff8800`. |
| `-a`, `--app` | Show this app's icon. Accepts an app name (`Safari`) or bundle id (`com.apple.Safari`). If no message is given, the app name is used. |
| `--` | Treat everything after as the message, even words starting with `-`. |
| `-h`, `--help` | Show usage. |
| `-v`, `--version` | Print version and exit. |

Messages longer than 256 characters are truncated with `…`, and long text wraps.
Invalid options exit with status 2; an app icon that can't be found prints a
warning and the HUD is shown without it.

### Examples

```sh
skhd-hud "Layout: BSP"
skhd-hud -a Safari
skhd-hud -c red -d 2 "Quit"
```

## skhd configuration

```
alt - s : open -a Safari && skhd-hud -a Safari
alt - t : open -a Terminal && skhd-hud -a Terminal
alt - q : skhd-hud -c red -d 2 "Quit"
alt - e : yabai -m space --layout bsp && skhd-hud "Layout: BSP"
```

skhd runs commands with a minimal `PATH`; use the full path to `skhd-hud` if it
isn't found.

## Releasing

1. Bump `version` in `skhd-hud.swift` and add an entry to `CHANGELOG.md`.
2. Commit, then push a matching version tag. GitHub Actions builds a universal
   binary and attaches it to a GitHub release (the build fails if the tag and
   `version` don't match):

```sh
git tag v0.1.0
git push origin v0.1.0
```
