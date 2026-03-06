# CLI 截图桥

CLI 截图桥是一个面向 `Claude CLI` / `Codex CLI` 场景的轻量截图中转工具。

它会监听剪贴板图片、自动保存为文件，并把文件路径写回剪贴板，让不支持直接贴图的输入框也能快速改走“路径投喂”方案。

## 仓库结构

- `Program.cs` / `ScreenshotListenerAssistant.csproj`：Windows 托盘版源码
- `macos/CLICaptureBridgeMac`：macOS 菜单栏版源码
- `.github/workflows/build-macos.yml`：macOS 云端构建工作流
- `docs/USAGE.en.md`：英文使用说明
- `docs/USAGE.zh-CN.md`：中文使用说明

## 构建与发布说明

- Windows 单文件 `.exe` 超过 GitHub 普通提交的单文件大小限制，建议通过 GitHub Releases 分发，不直接提交到仓库历史中。
- macOS 版本通过 GitHub Actions 的 `macos-latest` runner 云端构建，输出未签名 zip 产物。

## 快速入口

- 英文概览：`README.md`
- 英文使用说明：`docs/USAGE.en.md`
- 中文使用说明：`docs/USAGE.zh-CN.md`