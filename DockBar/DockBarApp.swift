import SwiftUI

@main
struct DockBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // We are NOT using SwiftUI Settings
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var taskbarController: TaskbarController?

    func applicationDidFinishLaunching(_ notification: Notification) {

        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)

        taskbarController = TaskbarController()
        taskbarController?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
