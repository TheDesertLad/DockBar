// File: SettingsView.swift
// This was built using Microsoft Copilot

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings = TaskbarSettings.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Appearance Section
                Text("Appearance")
                    .font(.title2)
                    .bold()

                Picker("Theme", selection: $settings.appearance) {
                    Text("System Preferences").tag("System Preferences")
                    Text("Dark").tag("Dark")
                    Text("Light").tag("Light")
                }
                .pickerStyle(.radioGroup)

                Divider().padding(.vertical, 10)

                // Blur Section
                Text("Blur Intensity")
                    .font(.title2)
                    .bold()

                Slider(value: $settings.blurAmount, in: 0...100)
                Text("Current: \(Int(settings.blurAmount))%")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider().padding(.vertical, 10)

                // Launcher Section
                Text("Launcher App")
                    .font(.title2)
                    .bold()

                Toggle("Enable Launcher", isOn: $settings.launcherEnabled)

                HStack {
                    TextField("Launcher App Path", text: $settings.launcherBundlePath)
                        .textFieldStyle(.roundedBorder)

                    Button("Choose…") {
                        chooseLauncherApp()
                    }
                }

                Divider().padding(.vertical, 10)

                // Layout Section
                Text("App Alignment")
                    .font(.title2)
                    .bold()

                Picker("Alignment", selection: $settings.layoutMode) {
                    Text("Left").tag("Left")
                    Text("Center").tag("Center")
                }
                .pickerStyle(.radioGroup)

                Divider().padding(.vertical, 10)

                // Quit Button
                Button("Quit DockBar") {
                    confirmQuit()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)
            }
            .padding(20)
        }
        .frame(minWidth: 450, minHeight: 380)
    }

    // MARK: - Actions

    private func chooseLauncherApp() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["app"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            settings.launcherBundlePath = url.path
        }
    }

    private func confirmQuit() {
        let alert = NSAlert()
        alert.messageText = "Quit DockBar?"
        alert.informativeText = "Are you sure you want to quit DockBar?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
    }
}
