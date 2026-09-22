import AppKit
import Carbon
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey?
    private let menu = NSMenu()
    private let stateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "开机自启", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        stateItem.isEnabled = false
        menu.addItem(stateItem)
        menu.addItem(NSMenuItem(title: "旋转 / 恢复", action: #selector(toggleRotation), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出 DesktopRotation", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }

        // ⌃⌘⇧R
        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_R),
                        modifiers: UInt32(controlKey | cmdKey | shiftKey)) { [weak self] in
            self?.toggleRotation()
        }

        // Keep the icon in sync if the rotation is changed elsewhere (e.g. System Settings).
        CGDisplayRegisterReconfigurationCallback({ _, _, userInfo in
            guard let userInfo else { return }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()
            DispatchQueue.main.async { delegate.refreshIcon() }
        }, Unmanaged.passUnretained(self).toOpaque())

        // `open DesktopRotation.app --args --launch-at-login on|off` toggles the login item from a script.
        if let i = CommandLine.arguments.firstIndex(of: "--launch-at-login"), i + 1 < CommandLine.arguments.count {
            setLaunchAtLogin(CommandLine.arguments[i + 1] == "on")
        }
        refreshLoginItem()
        refreshIcon()
    }

    @objc private func toggleLaunchAtLogin() {
        setLaunchAtLogin(SMAppService.mainApp.status != .enabled)
        refreshLoginItem()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("DesktopRotation: launch-at-login change failed: \(error)")
        }
    }

    private func refreshLoginItem() {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggleRotation()
        }
    }

    @objc private func toggleRotation() {
        if !DisplayRotator.toggle() {
            NSSound.beep()
        }
        refreshIcon()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func refreshIcon() {
        let rotation = DisplayRotator.currentRotation
        let rotated = rotation != 0
        let symbol = rotated ? "rectangle.portrait.rotate" : "rectangle.landscape.rotate"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Display rotation")
            ?? NSImage(systemSymbolName: "rotate.right", accessibilityDescription: "Display rotation")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = "当前旋转：\(rotation)°  （点击切换，⌃⌘⇧R）"
        stateItem.title = rotated ? "当前：旋转 \(rotation)°" : "当前：标准"
    }
}
