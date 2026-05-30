// File: DockBarApp.swift
// Updated for Open-Meteo WeatherService
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

        // Trigger Automation permission popup
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
    let script = """
    tell application "Finder"
        get name
    end tell
    """

    var error: NSDictionary?
    NSAppleScript(source: script)?.executeAndReturnError(&error)
}
