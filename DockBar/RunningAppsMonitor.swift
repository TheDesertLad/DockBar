// File: RunningAppsMonitor.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

class RunningAppsMonitor: ObservableObject {

    static let shared = RunningAppsMonitor()

    @Published var runningApps: [AppItem] = []

    private var timer: Timer?

    private init() {
        startMonitoring()
    }

    // MARK: - Monitoring
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.refreshRunningApps()
        }
    }

    private func refreshRunningApps() {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> AppItem? in
                guard let id = app.bundleIdentifier,
                      let url = app.bundleURL else { return nil }

                return AppItem(
                    bundleIdentifier: id,
                    bundleURL: url,
                    isPinned: false,
                    isRunning: true
                )
            }

        DispatchQueue.main.async {
            self.runningApps = apps
        }
    }
}
