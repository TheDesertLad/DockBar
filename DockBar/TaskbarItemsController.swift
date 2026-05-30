// File: TaskbarItemsController.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

class TaskbarItemsController: ObservableObject {

    static let shared = TaskbarItemsController()

    @Published var finalItems: [AppItem] = []
    @Published var shouldCenter: Bool = false

    // Weather widget state
    @Published var showWeatherWidget: Bool = false
    @Published var weatherWidgetMode: WeatherWidgetView.Mode = .inline

    private var pinnedApps: [(bundleID: String, path: String)] = []
    private var runningApps: [AppItem] = []

    var lastLauncherBundleID: String?

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
            .receive(on: RunLoop.main)
            .sink { [weak self] apps in
                guard let self else { return }
                self.runningApps = apps
                self.rebuildFinalList()
            }
            .store(in: &cancellables)
    }

    // MARK: - Observe Settings (with ordering fixes)

    private func observeSettings() {
        let settings = TaskbarSettings.shared

        // Launcher enabled toggle
        settings.$launcherEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildFinalList()
            }
            .store(in: &cancellables)

        // Launcher path changed
        settings.$launcherBundlePath
            .receive(on: RunLoop.main)
            .sink { [weak self] newPath in
                guard let self else { return }

                // Remove old launcher from pinned list
                if let oldID = self.lastLauncherBundleID {
                    self.pinnedApps.removeAll { $0.bundleID == oldID }
                }

                // Update launcher ID
                if let bundle = Bundle(path: newPath),
                   let id = bundle.bundleIdentifier {
                    self.lastLauncherBundleID = id
                }

                self.rebuildFinalList()
            }
            .store(in: &cancellables)

        // Layout mode (center vs left)
        settings.$layoutMode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                guard let self else { return }

                let centered = (mode == "Center")
                self.shouldCenter = centered

                // Weather mode depends on alignment
                self.weatherWidgetMode = centered ? .anchored : .inline

                // Rebuild AFTER mode is set
                self.rebuildFinalList()
            }
            .store(in: &cancellables)

        // Weather widget toggle
        settings.$showWeatherWidget
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                guard let self else { return }

                self.showWeatherWidget = enabled

                // Mode must be correct BEFORE rebuilding
                self.weatherWidgetMode = self.shouldCenter ? .anchored : .inline

                self.rebuildFinalList()
            }
            .store(in: &cancellables)
    }

    // MARK: - Build Final List (now stable)

    private func rebuildFinalList() {
        var items: [AppItem] = []

        // 1. Launcher
        if TaskbarSettings.shared.launcherEnabled,
           let launcher = buildLauncherItem() {
            items.append(launcher)
        }

        // 2. Weather widget (inline only when left-aligned)
        if showWeatherWidget && !shouldCenter {
            items.append(AppItem(
                bundleIdentifier: "__weather__",
                bundleURL: URL(fileURLWithPath: "/dev/null"),
                isPinned: false,
                isRunning: false
            ))
        }

        // 3. Pinned apps
        for pinned in pinnedApps {
            if let item = buildPinnedItem(bundleID: pinned.bundleID, path: pinned.path) {
                items.append(item)
            }
        }

        // 4. Running apps
        for running in runningApps {
            if let idx = items.firstIndex(where: { $0.bundleIdentifier == running.bundleIdentifier }) {
                items[idx].isRunning = true
            } else {
                items.append(running)
            }
        }

        finalItems = items
    }

    // MARK: - Build Items

    private func buildLauncherItem() -> AppItem? {
        let path = TaskbarSettings.shared.launcherBundlePath
        let url = URL(fileURLWithPath: path)

        guard let bundle = Bundle(url: url),
              let id = bundle.bundleIdentifier else { return nil }

        lastLauncherBundleID = id

        return AppItem(
            bundleIdentifier: id,
            bundleURL: url,
            isPinned: false,
            isRunning: false
        )
    }

    private func buildPinnedItem(bundleID: String, path: String) -> AppItem? {
        let url = URL(fileURLWithPath: path)
        return AppItem(
            bundleIdentifier: bundleID,
            bundleURL: url,
            isPinned: true,
            isRunning: runningApps.contains { $0.bundleIdentifier == bundleID }
        )
    }

    // MARK: - Reordering

    func movePinnedItem(from oldIndex: Int, to newIndex: Int) {
        // Offsets: [Launcher] [Weather?] [Pinned...]
        let launcherOffset = TaskbarSettings.shared.launcherEnabled ? 1 : 0
        let weatherOffset = (showWeatherWidget && !shouldCenter) ? 1 : 0

        let from = oldIndex - launcherOffset - weatherOffset
        let to = newIndex - launcherOffset - weatherOffset

        guard from >= 0, to >= 0,
              from < pinnedApps.count,
              to < pinnedApps.count else { return }

        let item = pinnedApps.remove(at: from)
        pinnedApps.insert(item, at: to)

        PinnedAppsManager.shared.savePinnedApps(pinnedApps)
        rebuildFinalList()
    }

    // Backwards-compat shims

    func movedPinnedItems(from oldIndex: Int, to newIndex: Int) {
        movePinnedItem(from: oldIndex, to: newIndex)
    }

    func movePinnedItems(from oldIndex: Int, to newIndex: Int) {
        movePinnedItem(from: oldIndex, to: newIndex)
    }

    // MARK: - Pin / Unpin

    func pinApp(bundleID: String, path: String) {
        if pinnedApps.contains(where: { $0.bundleID == bundleID }) { return }
        pinnedApps.append((bundleID, path))
        PinnedAppsManager.shared.savePinnedApps(pinnedApps)
        rebuildFinalList()
    }

    func unpinApp(bundleID: String) {
        pinnedApps.removeAll { $0.bundleID == bundleID }
        PinnedAppsManager.shared.savePinnedApps(pinnedApps)
        rebuildFinalList()
    }
}

