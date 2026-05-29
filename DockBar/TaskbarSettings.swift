import Foundation
import Combine
import AppKit

class TaskbarSettings: ObservableObject {
    static let shared = TaskbarSettings()

    private let appearanceKey = "TaskbarAppearance"
    private let blurKey = "TaskbarBlurAmount"
    private let launcherEnabledKey = "TaskbarLauncherEnabled"
    private let launcherAppPathKey = "TaskbarLauncherAppPath"
    private let launcherPositionKey = "TaskbarLauncherPosition"

    @Published var appearance: String {
        didSet { UserDefaults.standard.set(appearance, forKey: appearanceKey) }
    }

    @Published var blurAmount: Double {
        didSet { UserDefaults.standard.set(blurAmount, forKey: blurKey) }
    }

    @Published var launcherEnabled: Bool {
        didSet { UserDefaults.standard.set(launcherEnabled, forKey: launcherEnabledKey) }
    }

    @Published var launcherAppPath: String {
        didSet { UserDefaults.standard.set(launcherAppPath, forKey: launcherAppPathKey) }
    }

    @Published var launcherPosition: String {
        didSet { UserDefaults.standard.set(launcherPosition, forKey: launcherPositionKey) }
    }

    private init() {
        let rawAppearance = UserDefaults.standard.string(forKey: appearanceKey)

        if let value = rawAppearance {
            if value == "System Preferences" {
                self.appearance = "System"
                UserDefaults.standard.set("System", forKey: appearanceKey)
            } else if ["System", "Light", "Dark"].contains(value) {
                self.appearance = value
            } else {
                self.appearance = "System"
                UserDefaults.standard.set("System", forKey: appearanceKey)
            }
        } else {
            self.appearance = "System"
            UserDefaults.standard.set("System", forKey: appearanceKey)
        }

        if UserDefaults.standard.object(forKey: blurKey) == nil {
            self.blurAmount = 50
        } else {
            self.blurAmount = UserDefaults.standard.double(forKey: blurKey)
        }

        if UserDefaults.standard.object(forKey: launcherEnabledKey) == nil {
            self.launcherEnabled = true
        } else {
            self.launcherEnabled = UserDefaults.standard.bool(forKey: launcherEnabledKey)
        }

        self.launcherPosition = UserDefaults.standard.string(forKey: launcherPositionKey) ?? "Left"

        if let savedPath = UserDefaults.standard.string(forKey: launcherAppPathKey) {
            self.launcherAppPath = savedPath
        } else {
            self.launcherAppPath = TaskbarSettings.detectDefaultLauncher()
            UserDefaults.standard.set(self.launcherAppPath, forKey: launcherAppPathKey)
        }
    }

    static func detectDefaultLauncher() -> String {
        let appsApp = "/System/Applications/Apps.app"
        if FileManager.default.fileExists(atPath: appsApp) {
            return appsApp
        }

        let launchpad1 = "/System/Applications/Launchpad.app"
        if FileManager.default.fileExists(atPath: launchpad1) {
            return launchpad1
        }

        let launchpad2 = "/System/Applications/Utilities/Launchpad.app"
        if FileManager.default.fileExists(atPath: launchpad2) {
            return launchpad2
        }

        return "/System/Library/CoreServices/Finder.app"
    }
}
