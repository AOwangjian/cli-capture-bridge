# CLI Capture Bridge - Usage

## What it does

- Watches clipboard image changes
- Saves screenshots as PNG files automatically
- Writes image, file path, and file URL back to the clipboard
- Runs as a tray app on Windows or a menu-bar app on macOS

## Typical workflow

1. Launch the app.
2. Take a screenshot with Snipaste or any clipboard-based tool.
3. The app saves the image to the configured folder.
4. If the target input box supports images, paste as usual.
5. If it does not support images, paste the saved file path instead.

## Windows

- Main source: `Program.cs`
- Build target: `net8.0-windows`
- Packaging: publish as a single-file executable, then upload the zip package to GitHub Releases

## macOS

- Main source: `macos/CLICaptureBridgeMac/Sources/main.swift`
- Build with GitHub Actions or on a real Mac with Swift 5.9+
- Output: unsigned `.app` zipped as an artifact

## Notes

- macOS unsigned builds may require manual security approval on first launch.
- The repository should keep source code and workflow files; large binary packages should go to Releases.