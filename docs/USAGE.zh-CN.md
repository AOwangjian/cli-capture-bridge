# CLI 截图桥 - 使用说明

## 作用

- 监听剪贴板图片变化
- 自动保存截图为 PNG 文件
- 将图片、文件路径、文件 URL 一并写回剪贴板
- Windows 下以托盘运行，macOS 下以菜单栏运行

## 典型流程

1. 启动程序。
2. 用 Snipaste 或其他剪贴板截图工具进行截图。
3. 程序自动把图片保存到配置目录。
4. 如果目标输入框支持图片粘贴，就直接粘贴图片。
5. 如果目标输入框不支持图片粘贴，就改为粘贴保存后的文件路径。

## Windows

- 入口源码：`Program.cs`
- 构建目标：`net8.0-windows`
- 打包方式：发布为单文件可执行程序，再将 zip 包上传到 GitHub Releases

## macOS

- 入口源码：`macos/CLICaptureBridgeMac/Sources/main.swift`
- 可通过 GitHub Actions 或真实 Mac 上的 Swift 5.9+ 构建
- 输出为未签名 `.app` 的 zip 产物

## 注意事项

- macOS 未签名程序首次启动时，可能需要手动放行。
- 仓库中建议只保存源码与工作流，大体积二进制包放到 Releases。