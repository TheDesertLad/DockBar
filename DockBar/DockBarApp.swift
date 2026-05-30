// File: DockBarApp.swift
// This was built using Microsoft Copilot

import SwiftUI
import AppKit

@main
struct DockBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var taskbarController: TaskbarController?

    func applicationDidFinishLaunching(_ notification: Notification) {

        // Keep DockBar hidden from Dock
        NSApp.setActivationPolicy(.accessory)

        // 🔥 Trigger Automation permission popup for Finder
        requestAutomationPermission()

        // Initialize WeatherService (auto-refreshes itself)
        _ = WeatherService.shared

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

    // This reliably forces macOS to show:
    // “DockBar wants to control Finder. Allow?”
    //
    // It is harmless and does not modify anything.
    let script = """
    tell application "Finder"
        count windows
    end tell
    """

    var error: NSDictionary?
    NSAppleScript(source: script)?.executeAndReturnError(&error)

    if let error = error {
        print("Automation permission request error: \(error)")
    }
}

