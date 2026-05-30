// File: DockBarApp.swift
// Temporary version to obtain Automation permission

import SwiftUI
import AppKit

@main
struct DockBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // We are NOT using SwiftUI Settings
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var taskbarController: TaskbarController?

    func applicationDidFinishLaunching(_ notification: Notification) {

        // TEMPORARY: Make DockBar a regular app so macOS will show the Automation popup
        NSApp.setActivationPolicy(.accessory)

        // 🔥 Trigger Automation permission popup
        requestAutomationPermission()

        // Launch the taskbar window
        taskbarController = TaskbarController()
        taskbarController?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

// MARK: - Automation Permission Trigger
private func requestAutomationPermission() {
    let script = """
    tell application "Finder"
        get name
    end tell
    """

    var error: NSDictionary?
    NSAppleScript(source: script)?.executeAndReturnError(&error)
}

