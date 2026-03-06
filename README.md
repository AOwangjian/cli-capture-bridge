# CLI Capture Bridge

CLI Capture Bridge is a lightweight tray/menu-bar tool for screenshot handoff in `Claude CLI` and `Codex CLI` workflows.

It watches clipboard images, saves them automatically, and writes the file path back to the clipboard so image-unfriendly input boxes still have a smooth fallback.

## Repository layout

- `Program.cs` / `ScreenshotListenerAssistant.csproj`: Windows tray app source
- `macos/CLICaptureBridgeMac`: native macOS menu-bar app source
- `.github/workflows/build-macos.yml`: GitHub Actions workflow for macOS build
- `docs/USAGE.en.md`: English usage guide
- `docs/USAGE.zh-CN.md`: 中文使用说明

## Build and release notes

- The Windows single-file `.exe` is larger than GitHub's regular file-size limit, so it should be distributed through GitHub Releases instead of normal Git commits.
- The macOS app is built in GitHub Actions on `macos-latest` and exported as an unsigned zip artifact.

## Quick links

- Chinese overview: `README.zh-CN.md`
- English usage: `docs/USAGE.en.md`
- Chinese usage: `docs/USAGE.zh-CN.md`