// File: AppItem.swift
// This was built using Microsoft Copilot

import AppKit

struct AppItem: Identifiable, Equatable {

    // Unique identity for SwiftUI diffing
    let id = UUID()

    let bundleIdentifier: String
    var bundleURL: URL

    var displayName: String {
        FileManager.default.displayName(atPath: bundleURL.path)
    }

    var icon: NSImage {
        let img = NSWorkspace.shared.icon(forFile: bundleURL.path)
        img.size = NSSize(width: 40, height: 40)
        return img
    }

    var isPinned: Bool
    var isRunning: Bool

    init(bundleIdentifier: String,
         bundleURL: URL,
         isPinned: Bool,
         isRunning: Bool) {

        self.bundleIdentifier = bundleIdentifier
        self.bundleURL = bundleURL
        self.isPinned = isPinned
        self.isRunning = isRunning
    }

    // MARK: - Equatable
    static func == (lhs: AppItem, rhs: AppItem) -> Bool {
        // UUID makes each rebuild unique
        return lhs.id == rhs.id
    }
}

