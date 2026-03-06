import AppKit
import Darwin
import Foundation

private let appName = "CLI 截图桥"
private let launchAgentLabel = "com.codex.cli-capture-bridge"

struct AppConfig: Codable {
    var saveDirectory: String

    static func `default`() -> AppConfig {
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Pictures", isDirectory: true)
        return AppConfig(saveDirectory: pictures.appendingPathComponent("CLI截图桥", isDirectory: true).path)
    }
}

final class ClipboardBridgeApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var toggleMenuItem: NSMenuItem!
    private var startupMenuItem: NSMenuItem!
    private var timer: Timer?

    private var enabled = true
    private var ignoreNextClipboardChange = false
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var savedCount = 0
    private var lastSavedPath = ""

    private let fileManager = FileManager.default
    private lazy var appSupportDirectory: URL = {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        return base.appendingPathComponent("CLICaptureBridgeMac", isDirectory: true)
    }()
    private lazy var configURL: URL = appSupportDirectory.appendingPathComponent("config.json")
    private lazy var launchAgentURL: URL = {
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        return home.appendingPathComponent("Library/LaunchAgents/\(launchAgentLabel).plist")
    }()

    private var config = AppConfig.default()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        loadConfig()
        ensureSaveDirectory()
        setupStatusItem()
        refreshMenuState()

        timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(handleTimerTick), userInfo: nil, repeats: true)
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "link.circle.fill", accessibilityDescription: appName) {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "桥"
            }
        }

        let menu = NSMenu()
        statusMenuItem = NSMenuItem(title: "状态: 运行中", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false

        toggleMenuItem = NSMenuItem(title: "暂停监听", action: #selector(toggleEnabled), keyEquivalent: "")
        toggleMenuItem.target = self

        let chooseFolderItem = NSMenuItem(title: "设置保存目录", action: #selector(chooseSaveDirectory), keyEquivalent: "")
        chooseFolderItem.target = self
        let openFolderItem = NSMenuItem(title: "打开保存目录", action: #selector(openSaveDirectory), keyEquivalent: "")
        openFolderItem.target = self
        let copyPathItem = NSMenuItem(title: "复制最后路径", action: #selector(copyLastPath), keyEquivalent: "")
        copyPathItem.target = self

        startupMenuItem = NSMenuItem(title: "开机启动", action: #selector(toggleStartup), keyEquivalent: "")
        startupMenuItem.target = self

        let exitItem = NSMenuItem(title: "退出", action: #selector(exitApp), keyEquivalent: "q")
        exitItem.target = self

        menu.addItem(statusMenuItem)
        menu.addItem(toggleMenuItem)
        menu.addItem(.separator())
        menu.addItem(chooseFolderItem)
        menu.addItem(openFolderItem)
        menu.addItem(copyPathItem)
        menu.addItem(.separator())
        menu.addItem(startupMenuItem)
        menu.addItem(.separator())
        menu.addItem(exitItem)
        statusItem.menu = menu
    }

    private func refreshMenuState() {
        if enabled {
            statusMenuItem.title = savedCount > 0 ? "状态: 运行中 (已保存 \(savedCount) 张)" : "状态: 运行中"
            toggleMenuItem.title = "暂停监听"
        } else {
            statusMenuItem.title = "状态: 已暂停"
            toggleMenuItem.title = "继续监听"
        }
        startupMenuItem.state = isStartupEnabled() ? .on : .off
    }

    @objc private func handleTimerTick() {
        guard enabled else { return }

        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount

        if ignoreNextClipboardChange {
            ignoreNextClipboardChange = false
            return
        }

        guard let image = readClipboardImage(from: pasteboard) else { return }

        do {
            let savedURL = try saveImage(image)
            writeBackToClipboard(image: image, fileURL: savedURL)
            savedCount += 1
            lastSavedPath = savedURL.path
            refreshMenuState()
        } catch {
            NSSound.beep()
        }
    }

    private func readClipboardImage(from pasteboard: NSPasteboard) -> NSImage? {
        let classes: [AnyClass] = [NSImage.self]
        let objects = pasteboard.readObjects(forClasses: classes, options: nil)
        return objects?.first as? NSImage
    }

    private func saveImage(_ image: NSImage) throws -> URL {
        ensureSaveDirectory()

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: appName, code: 1)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss_SSS"
        let fileName = formatter.string(from: Date()) + ".png"
        let fileURL = URL(fileURLWithPath: config.saveDirectory, isDirectory: true).appendingPathComponent(fileName)
        try pngData.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func writeBackToClipboard(image: NSImage, fileURL: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let objects: [NSPasteboardWriting] = [image, fileURL as NSURL, fileURL.path as NSString]
        pasteboard.writeObjects(objects)
        ignoreNextClipboardChange = true
        lastChangeCount = pasteboard.changeCount
    }

    @objc private func toggleEnabled() {
        enabled.toggle()
        refreshMenuState()
    }

    @objc private func chooseSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: config.saveDirectory, isDirectory: true)

        if panel.runModal() == .OK, let url = panel.url {
            config.saveDirectory = url.path
            ensureSaveDirectory()
            saveConfig()
        }
    }

    @objc private func openSaveDirectory() {
        ensureSaveDirectory()
        let url = URL(fileURLWithPath: config.saveDirectory, isDirectory: true)
        NSWorkspace.shared.open(url)
    }

    @objc private func copyLastPath() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(lastSavedPath.isEmpty ? "尚无保存记录" : lastSavedPath, forType: .string)
    }

    @objc private func toggleStartup() {
        do {
            if isStartupEnabled() {
                try disableStartup()
            } else {
                try enableStartup()
            }
            refreshMenuState()
        } catch {
            NSSound.beep()
        }
    }

    private func isStartupEnabled() -> Bool {
        fileManager.fileExists(atPath: launchAgentURL.path)
    }

    private func enableStartup() throws {
        let agentsDirectory = launchAgentURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: agentsDirectory, withIntermediateDirectories: true, attributes: nil)

        let executablePath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
        let plist: [String: Any] = [
            "Label": launchAgentLabel,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProcessType": "Interactive"
        ]

        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: launchAgentURL, options: .atomic)

        _ = shell("/bin/launchctl", ["bootout", "gui/\(getuid())", launchAgentURL.path])
        _ = shell("/bin/launchctl", ["bootstrap", "gui/\(getuid())", launchAgentURL.path])
    }

    private func disableStartup() throws {
        _ = shell("/bin/launchctl", ["bootout", "gui/\(getuid())", launchAgentURL.path])
        if fileManager.fileExists(atPath: launchAgentURL.path) {
            try fileManager.removeItem(at: launchAgentURL)
        }
    }

    private func shell(_ launchPath: String, _ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return -1
        }
    }

    @objc private func exitApp() {
        NSApp.terminate(nil)
    }

    private func loadConfig() {
        guard let data = try? Data(contentsOf: configURL),
              let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            config = .default()
            return
        }
        config = decoded
    }

    private func saveConfig() {
        do {
            try fileManager.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true, attributes: nil)
            let data = try JSONEncoder().encode(config)
            try data.write(to: configURL, options: .atomic)
        } catch {
            NSSound.beep()
        }
    }

    private func ensureSaveDirectory() {
        let url = URL(fileURLWithPath: config.saveDirectory, isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
}

let app = NSApplication.shared
let delegate = ClipboardBridgeApp()
app.delegate = delegate
app.run()
