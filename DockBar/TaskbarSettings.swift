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
        appearance = UserDefaults.standard.string(forKey: appearanceKey) ?? "System"

        let savedBlur = UserDefaults.standard.double(forKey: blurKey)
        blurAmount = savedBlur == 0 ? 50 : savedBlur

        launcherEnabled = UserDefaults.standard.object(forKey: launcherEnabledKey) as? Bool ?? true

        layoutMode = UserDefaults.standard.string(forKey: layoutModeKey) ?? "Left"

        if let savedPath = UserDefaults.standard.string(forKey: launcherPathKey) {
            launcherBundlePath = savedPath
        } else {
            launcherBundlePath = TaskbarSettings.defaultLauncherPath()
            UserDefaults.standard.set(launcherBundlePath, forKey: launcherPathKey)
        }
    }

    static func defaultLauncherPath() -> String {
        let appsApp = "/System/Applications/Apps.app"
        let launchpadApp = "/System/Applications/Launchpad.app"
        let oldLaunchpadApp = "/System/Applications/Utilities/Launchpad.app"

        if FileManager.default.fileExists(atPath: appsApp) { return appsApp }
        if FileManager.default.fileExists(atPath: launchpadApp) { return launchpadApp }
        return oldLaunchpadApp
    }
}

