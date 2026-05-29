//File: SettingsWindowController.swift
//This was built using Microsoft Copilot

import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController {

    static let shared = SettingsWindowController()

    private init() {
        let view = SettingsView()
        let hosting = NSHostingView(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Taskbar Settings"
        window.center()
        window.contentView = hosting

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
