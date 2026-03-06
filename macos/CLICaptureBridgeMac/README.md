# CLI 截图桥 macOS 版

这是 `CLI 截图桥` 的原生 macOS 菜单栏实现，核心能力与 Windows 版对齐：

- 监听剪贴板图片变化
- 自动保存为 PNG
- 同时写回图片、文件路径、文件 URL
- 菜单栏常驻，支持切换保存目录
- 支持通过 LaunchAgent 开机启动

## 目录结构

- `Package.swift`：Swift Package 定义
- `Sources/main.swift`：macOS 菜单栏应用入口
- `scripts/package-app.sh`：在 Mac 上打包 `.app`

## 在 Mac 上构建

```bash
cd macos/CLICaptureBridgeMac
swift build -c release
```

直接运行可执行文件：

```bash
.build/release/CLICaptureBridgeMac
```

## 打包为 `.app`

```bash
cd macos/CLICaptureBridgeMac
chmod +x scripts/package-app.sh
./scripts/package-app.sh
```

输出目录：`macos/CLICaptureBridgeMac/dist/CLI截图桥.app`

## 已实现的差异

- 菜单栏图标使用系统 Symbol，不复用 Windows 的 `.ico`
- 开机启动使用 `~/Library/LaunchAgents/com.codex.cli-capture-bridge.plist`
- 当前未添加系统通知弹窗，状态通过菜单栏菜单反馈

## 说明

当前环境是 Windows，无法在本机直接编译或验收 macOS 二进制。
源码已补齐，需在一台安装 Xcode Command Line Tools 的 Mac 上执行上述命令验证。
