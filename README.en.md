# CLI Capture Bridge

[简体中文](README.md)

CLI Capture Bridge is a lightweight screenshot handoff tool built for `Claude CLI` and `Codex CLI` workflows.

It watches clipboard images, saves them automatically, and writes the saved file path back to the clipboard so image-unfriendly input boxes still have a clean fallback.

## Features

- Watches clipboard image changes
- Saves screenshots as PNG files automatically
- Writes image, file path, and file URL back to the clipboard
- Runs as a tray app on Windows and a menu-bar app on macOS

## Repository layout

- `Program.cs` / `ScreenshotListenerAssistant.csproj`: Windows tray app source
- `macos/CLICaptureBridgeMac`: native macOS menu-bar app source
- `.github/workflows/build-macos.yml`: GitHub Actions workflow for macOS builds
- `docs/USAGE.en.md`: English usage guide
- `docs/USAGE.zh-CN.md`: Chinese usage guide

## Build and release

- The Windows single-file `.exe` is larger than GitHub's normal file-size limit, so it should be distributed through GitHub Releases
- The macOS build runs on GitHub Actions using `macos-latest` and exports an unsigned zip artifact

## Docs

- Chinese README: `README.md`
- Chinese usage: `docs/USAGE.zh-CN.md`
- English usage: `docs/USAGE.en.md`