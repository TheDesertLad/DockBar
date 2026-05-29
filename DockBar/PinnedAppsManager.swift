// File: PinnedAppsManager.swift
// This was built using Microsoft Copilot

import AppKit

class PinnedAppsManager {

    static let shared = PinnedAppsManager()

    private let directoryURL: URL
    private let plistURL: URL

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        directoryURL = appSupport.appendingPathComponent("DockBar", isDirectory: true)
        plistURL = directoryURL.appendingPathComponent("pinnedApps.plist")

        createDirectoryIfNeeded()
    }

    // MARK: - Directory Setup
    private func createDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }
    }

    // MARK: - Load Pinned Apps
    func loadPinnedApps() -> [(bundleID: String, path: String)] {
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
              ) as? [[String: String]] else {
            return []
        }

        return plist.compactMap { dict in
            guard let id = dict["bundleIdentifier"],
                  let path = dict["bundlePath"] else { return nil }
            return (id, path)
        }
    }

    // MARK: - Save Pinned Apps
    func savePinnedApps(_ items: [(bundleID: String, path: String)]) {
        let plistArray = items.map { [
            "bundleIdentifier": $0.bundleID,
            "bundlePath": $0.path
        ]}

        if let data = try? PropertyListSerialization.data(
            fromPropertyList: plistArray,
            format: .xml,
            options: 0
        ) {
            try? data.write(to: plistURL)
        }
    }

    // MARK: - Pin / Unpin
    func pinApp(bundleID: String, path: String) {
        var items = loadPinnedApps()

        if !items.contains(where: { $0.bundleID == bundleID }) {
            items.append((bundleID, path))
            savePinnedApps(items)
        }
    }

    func unpinApp(bundleID: String) {
        var items = loadPinnedApps()
        items.removeAll { $0.bundleID == bundleID }
        savePinnedApps(items)
    }

    // MARK: - Drag-to-Pin
    func handleDragURL(_ url: URL) {
        guard url.pathExtension == "app" else { return }

        if let bundle = Bundle(url: url),
           let id = bundle.bundleIdentifier {
            pinApp(bundleID: id, path: url.path)
        }
    }
}
