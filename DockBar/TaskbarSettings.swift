// File: TaskbarSettings.swift
// This was built using Microsoft Copilot

import Foundation
import Combine

class TaskbarSettings: ObservableObject {
    static let shared = TaskbarSettings()

    private let appearanceKey = "TaskbarAppearance"
    private let blurKey = "TaskbarBlurAmount"
    private let launcherEnabledKey = "TaskbarLauncherEnabled"
    private let launcherPathKey = "TaskbarLauncherPath"
    private let layoutModeKey = "TaskbarLayoutMode"

    @Published var appearance: String {
        didSet { UserDefaults.standard.set(appearance, forKey: appearanceKey) }
    }

    @Published var blurAmount: Double {
        didSet { UserDefaults.standard.set(blurAmount, forKey: blurKey) }
    }

    @Published var launcherEnabled: Bool {
        didSet { UserDefaults.standard.set(launcherEnabled, forKey: launcherEnabledKey) }
    }

    @Published var launcherBundlePath: String {
        didSet { UserDefaults.standard.set(launcherBundlePath, forKey: launcherPathKey) }
    }

    @Published var layoutMode: String {
        didSet { UserDefaults.standard.set(layoutMode, forKey: layoutModeKey) }
    }

    private init() {
        // Appearance
        self.appearance = UserDefaults.standard.string(forKey: appearanceKey) ?? "System Preferences"

        // Blur
        let savedBlur = UserDefaults.standard.double(forKey: blurKey)
        self.blurAmount = savedBlur == 0 ? 50 : savedBlur

        // Launcher Enabled
        self.launcherEnabled = UserDefaults.standard.object(forKey: launcherEnabledKey) as? Bool ?? true

        // Layout Mode
        self.layoutMode = UserDefaults.standard.string(forKey: layoutModeKey) ?? "Left"

        // Launcher Path
        if let savedPath = UserDefaults.standard.string(forKey: launcherPathKey) {
            self.launcherBundlePath = savedPath
        } else {
            self.launcherBundlePath = TaskbarSettings.defaultLauncherPath()
            UserDefaults.standard.set(self.launcherBundlePath, forKey: launcherPathKey)
        }
    }

    // MARK: - Default Launcher Detection
    static func defaultLauncherPath() -> String {
        let appsApp = "/System/Applications/Apps.app"
        let launchpadApp = "/System/Applications/Launchpad.app"
        let oldLaunchpadApp = "/System/Applications/Utilities/Launchpad.app"

        if FileManager.default.fileExists(atPath: appsApp) {
            return appsApp
        }
        if FileManager.default.fileExists(atPath: launchpadApp) {
            return launchpadApp
        }
        return oldLaunchpadApp
    }
}

