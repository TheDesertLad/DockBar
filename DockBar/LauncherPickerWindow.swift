import AppKit
import UniformTypeIdentifiers

class LauncherPickerWindow {

    static func openPicker() {
        let panel = NSOpenPanel()
        panel.title = "Choose Launcher App"
        panel.message = "Select an application to use as your Launcher (Start Menu) button."
        panel.prompt = "Choose"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        // Modern API (macOS 12+)
        panel.allowedContentTypes = [UTType.applicationBundle]

        panel.begin { response in
            guard response == .OK,
                  let url = panel.url else { return }

            let path = url.path

            // Save the selected launcher app
            TaskbarSettings.shared.launcherAppPath = path

            // Force UI update
            NotificationCenter.default.post(name: .launcherAppChanged, object: nil)
        }
    }
}

extension Notification.Name {
    static let launcherAppChanged = Notification.Name("LauncherAppChanged")
}
