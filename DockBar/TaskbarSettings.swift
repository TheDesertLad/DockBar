import Foundation
import Combine

class TaskbarSettings: ObservableObject {
    static let shared = TaskbarSettings()

    private let appearanceKey = "TaskbarAppearance"
    private let blurKey = "TaskbarBlurAmount"

    @Published var appearance: String {
        didSet {
            UserDefaults.standard.set(appearance, forKey: appearanceKey)
        }
    }

    @Published var blurAmount: Double {
        didSet {
            UserDefaults.standard.set(blurAmount, forKey: blurKey)
        }
    }

    private init() {
        // Load saved values or defaults
        self.appearance = UserDefaults.standard.string(forKey: appearanceKey) ?? "System Preferences"
        self.blurAmount = UserDefaults.standard.double(forKey: blurKey)

        // If blurAmount was never saved, default to 50
        if UserDefaults.standard.object(forKey: blurKey) == nil {
            self.blurAmount = 50
        }
    }
}
