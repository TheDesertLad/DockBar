// File: TaskbarItemsController.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

class TaskbarItemsController: ObservableObject {

    static let shared = TaskbarItemsController()

    @Published var finalItems: [AppItem] = []
    @Published var shouldCenter: Bool = false

    private var pinnedApps: [(bundleID: String, path: String)] = []
    private var runningApps: [AppItem] = []

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadPinnedApps()
        observeRunningApps()
        observeSettings()
    }

    // MARK: - Load Pinned Apps
    private func loadPinnedApps() {
        pinnedApps = PinnedAppsManager.shared.loadPinnedApps()
        rebuildFinalList()
    }

    // MARK: - Observe Running Apps
    private func observeRunningApps() {
        RunningAppsMonitor.shared.$runningApps
            .sink { [weak self] apps in
                self?.runningApps = apps
                self?.rebuildFinalList()
            }
            .store(in: &cancellables)
    }

    // MARK: - Observe Settings
    private func observeSettings() {
        let settings = TaskbarSettings.shared

        settings.$launcherEnabled
            .sink { [weak self] _ in self?.rebuildFinalList() }
            .store(in: &cancellables)

        settings.$launcherBundlePath
            .sink { [weak self] _ in self?.rebuildFinalList() }
            .store(in: &cancellables)

        settings.$layoutMode
            .sink { [weak self] _ in self?.rebuildFinalList() }
            .store(in: &cancellables)
    }

    // MARK: - Build Final List
    private func rebuildFinalList() {
        var items: [AppItem] = []

        // --- 1. Launcher ---
        if TaskbarSettings.shared.launcherEnabled {
            if let launcher = buildLauncherItem() {
                items.append(launcher)
            }
        }

        // --- 2. Pinned Apps ---
        for pinned in pinnedApps {
            if let item = buildPinnedItem(bundleID: pinned.bundleID, path: pinned.path) {
                items.append(item)
            }
        }

        // --- 3. Running Apps ---
        for running in runningApps {
            if let index = items.firstIndex(where: { $0.bundleIdentifier == running.bundleIdentifier }) {
                items[index].isRunning = true
            } else {
                items.append(running)
            }
        }

        // --- 4. Centering Logic ---
        if TaskbarSettings.shared.layoutMode == "Center" {
            shouldCenter = true
        } else {
            shouldCenter = false
        }

        DispatchQueue.main.async {
            self.finalItems = items
        }
    }

    // MARK: - Build Launcher Item
    private func buildLauncherItem() -> AppItem? {
        let path = TaskbarSettings.shared.launcherBundlePath
        let url = URL(fileURLWithPath: path)

        guard let bundle = Bundle(url: url),
              let id = bundle.bundleIdentifier else {
            return nil
        }

        return AppItem(
            bundleIdentifier: id,
            bundleURL: url,
            isPinned: true,
            isRunning: false
        )
    }

    // MARK: - Build Pinned Item
    private func buildPinnedItem(bundleID: String, path: String) -> AppItem? {
        let url = URL(fileURLWithPath: path)

        var resolvedURL = url
        if !FileManager.default.fileExists(atPath: url.path) {
            if let newURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                resolvedURL = newURL
            }
        }

        let isRunning = runningApps.contains { $0.bundleIdentifier == bundleID }

        return AppItem(
            bundleIdentifier: bundleID,
            bundleURL: resolvedURL,
            isPinned: true,
            isRunning: isRunning
        )
    }

    // MARK: - Reordering
    func movePinnedItem(from oldIndex: Int, to newIndex: Int) {
        let offset = TaskbarSettings.shared.launcherEnabled ? 1 : 0

        let from = oldIndex - offset
        let to = newIndex - offset

        guard from >= 0, to >= 0,
              from < pinnedApps.count,
              to < pinnedApps.count else { return }

        let item = pinnedApps.remove(at: from)
        pinnedApps.insert(item, at: to)

        PinnedAppsManager.shared.savePinnedApps(pinnedApps)
        rebuildFinalList()
    }

    // MARK: - Pin / Unpin
    func pinApp(bundleID: String, path: String) {
        if pinnedApps.contains(where: { $0.bundleID == bundleID }) {
            return
        }

        guard let currentIndex = finalItems.firstIndex(where: { $0.bundleIdentifier == bundleID }) else {
            pinnedApps.append((bundleID: bundleID, path: path))
            PinnedAppsManager.shared.savePinnedApps(pinnedApps)
            rebuildFinalList()
            return
        }

        let offset = TaskbarSettings.shared.launcherEnabled ? 1 : 0
        let insertIndex = max(0, min(currentIndex - offset, pinnedApps.count))

        pinnedApps.insert((bundleID: bundleID, path: path), at: insertIndex)

        PinnedAppsManager.shared.savePinnedApps(pinnedApps)
        rebuildFinalList()
    }

    func unpinApp(bundleID: String) {
        pinnedApps.removeAll { $0.bundleID == bundleID }
        PinnedAppsManager.shared.savePinnedApps(pinnedApps)
        rebuildFinalList()
    }
}

