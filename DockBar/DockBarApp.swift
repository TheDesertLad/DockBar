import SwiftUI

@main
struct DockBarApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // We use our own settings window
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    var taskbarWindow: TaskbarWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {

        // Create the taskbar window
        taskbarWindow = TaskbarWindow()
        taskbarWindow?.makeKeyAndOrderFront(nil)

        // Remove default Settings menu item
        if let settingsMenu = NSApp.mainMenu?.item(withTitle: "Settings") {
            settingsMenu.isHidden = true
        }
    }

    @objc func openSettingsWindow() {
        SettingsWindowController.shared.show()
    }
}
