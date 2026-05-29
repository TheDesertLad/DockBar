// File: AppItem.swift
// This was built using Microsoft Copilot

import AppKit

struct AppItem: Identifiable, Equatable {
    let id = UUID()

    let bundleIdentifier: String
    var bundleURL: URL
    var displayName: String
    var icon: NSImage

    var isPinned: Bool
    var isRunning: Bool

    // MARK: - Initializer
    init(bundleIdentifier: String,
         bundleURL: URL,
         isPinned: Bool,
         isRunning: Bool) {

        self.bundleIdentifier = bundleIdentifier
        self.bundleURL = bundleURL
        self.isPinned = isPinned
        self.isRunning = isRunning

        // Resolve display name
        let name = FileManager.default.displayName(atPath: bundleURL.path)
        self.displayName = name

        // Resolve icon
        let icon = NSWorkspace.shared.icon(forFile: bundleURL.path)
        icon.size = NSSize(width: 40, height: 40)
        self.icon = icon
    }
}
