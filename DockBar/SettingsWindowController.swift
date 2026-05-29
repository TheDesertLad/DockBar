import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController {

    static let shared = SettingsWindowController()

    private init() {
        let settingsView = SettingsView()

        let hosting = NSHostingController(rootView: settingsView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Taskbar Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = hosting.view

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
