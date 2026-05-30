// File: DockBarApp.swift
// Temporary version to obtain Automation permission

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

        NSApp.setActivationPolicy(.accessory)

        requestAutomationPermission()

        if #available(macOS 13.0, *) {
            TaskbarWeatherService.shared.start()
        }

        taskbarController = TaskbarController()
        taskbarController?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

private func requestAutomationPermission() {
    let script = """
    tell application "Finder"
        get name
    end tell
    """

    var error: NSDictionary?
    NSAppleScript(source: script)?.executeAndReturnError(&error)
}
