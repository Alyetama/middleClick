import AppKit
import ApplicationServices
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        promptForAccessibilityIfNeeded()
        GestureDetector.shared.start()
    }

    // MARK: - Status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursorarrow.click.2",
                                   accessibilityDescription: "MiddleClick")
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // Rebuild the menu each time it opens so state stays in sync.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let s = Settings.shared

        let header = NSMenuItem(title: "MiddleClick", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let enabled = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabled.target = self
        enabled.state = s.enabled ? .on : .off
        menu.addItem(enabled)

        // Fingers submenu
        let fingersItem = NSMenuItem(title: "Fingers", action: nil, keyEquivalent: "")
        let fingersMenu = NSMenu()
        for n in [2, 3, 4] {
            let item = NSMenuItem(title: "\(n) fingers", action: #selector(setFingers(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = n
            item.state = (s.fingers == n) ? .on : .off
            fingersMenu.addItem(item)
        }
        fingersItem.submenu = fingersMenu
        menu.addItem(fingersItem)

        // Sensitivity label + slider
        let label = NSMenuItem(title: "Sensitivity", action: nil, keyEquivalent: "")
        label.isEnabled = false
        menu.addItem(label)
        menu.addItem(makeSliderItem(value: s.sensitivity))

        menu.addItem(.separator())

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        login.state = isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(login)

        let ax = NSMenuItem(title: accessibilityGranted ? "Accessibility: Granted"
                                                         : "Grant Accessibility Access…",
                            action: #selector(openAccessibility), keyEquivalent: "")
        ax.target = self
        ax.isEnabled = !accessibilityGranted
        menu.addItem(ax)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func makeSliderItem(value: Double) -> NSMenuItem {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 28))
        let slider = NSSlider(value: value, minValue: 0, maxValue: 1,
                              target: self, action: #selector(sensitivityChanged(_:)))
        slider.frame = NSRect(x: 20, y: 4, width: 180, height: 20)
        slider.isContinuous = true
        container.addSubview(slider)
        let item = NSMenuItem()
        item.view = container
        return item
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        Settings.shared.enabled.toggle()
    }

    @objc private func setFingers(_ sender: NSMenuItem) {
        if let n = sender.representedObject as? Int {
            Settings.shared.fingers = n
        }
    }

    @objc private func sensitivityChanged(_ sender: NSSlider) {
        Settings.shared.sensitivity = sender.doubleValue
    }

    @objc private func toggleLaunchAtLogin() {
        setLaunchAtLogin(!isLaunchAtLoginEnabled)
    }

    @objc private func openAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Accessibility

    private var accessibilityGranted: Bool { AXIsProcessTrusted() }

    private func promptForAccessibilityIfNeeded() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    // MARK: - Launch at login

    private var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("MiddleClick: launch-at-login change failed: \(error)")
        }
    }
}
