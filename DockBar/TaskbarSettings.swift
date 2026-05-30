// File: TaskbarSettings.swift
// This was built using Microsoft Copilot

import Foundation
import Combine

class TaskbarSettings: ObservableObject {

    static let shared = TaskbarSettings()

    // MARK: - UserDefaults Keys
    private let appearanceKey = "TaskbarAppearance"
    private let blurKey = "TaskbarBlurAmount"
    private let launcherEnabledKey = "TaskbarLauncherEnabled"
    private let launcherPathKey = "TaskbarLauncherPath"
    private let layoutModeKey = "TaskbarLayoutMode"
    private let weatherEnabledKey = "TaskbarWeatherEnabled"
    private let showDesktopKey = "TaskbarShowDesktopEnabled"

    // MARK: - Published Settings

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

    @Published var weatherEnabled: Bool {
        didSet { UserDefaults.standard.set(weatherEnabled, forKey: weatherEnabledKey) }
    }

    @Published var showDesktopButtonEnabled: Bool {
        didSet { UserDefaults.standard.set(showDesktopButtonEnabled, forKey: showDesktopKey) }
    }

    // MARK: - Initializer

    private init() {
        let defaults = UserDefaults.standard

        // Appearance
        appearance = defaults.string(forKey: appearanceKey) ?? "System"

        // Blur
        let savedBlur = defaults.double(forKey: blurKey)
        blurAmount = savedBlur == 0 ? 50 : savedBlur

        // Launcher Enabled
        launcherEnabled = defaults.object(forKey: launcherEnabledKey) as? Bool ?? true

        // Layout Mode
        layoutMode = defaults.string(forKey: layoutModeKey) ?? "Left"

        // Launcher Path (fixed: compute BEFORE assigning to @Published)
        let savedPath = defaults.string(forKey: launcherPathKey)
        let defaultPath = TaskbarSettings.defaultLauncherPath()
        let finalPath = savedPath ?? defaultPath
        launcherBundlePath = finalPath
        defaults.set(finalPath, forKey: launcherPathKey)

        // Weather
        weatherEnabled = defaults.object(forKey: weatherEnabledKey) as? Bool ?? true

        // Show Desktop Button
        showDesktopButtonEnabled = defaults.object(forKey: showDesktopKey) as? Bool ?? true
    }

    // MARK: - Default Launcher Path

    static func defaultLauncherPath() -> String {
        let appsApp = "/System/Applications/Apps.app"
        let launchpadApp = "/System/Applications/Launchpad.app"
        let oldLaunchpadApp = "/System/Applications/Utilities/Launchpad.app"

        if FileManager.default.fileExists(atPath: appsApp) { return appsApp }
        if FileManager.default.fileExists(atPath: launchpadApp) { return launchpadApp }
        return oldLaunchpadApp
    }
}
