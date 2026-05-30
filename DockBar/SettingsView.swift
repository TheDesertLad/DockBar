// File: SettingsView.swift
// This was built using Microsoft Copilot

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {

    @ObservedObject private var settings = TaskbarSettings.shared
    @ObservedObject private var items = TaskbarItemsController.shared

    @State private var showQuitConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Appearance
            Picker("Appearance", selection: $settings.appearance) {
                Text("System").tag("System")
                Text("Light").tag("Light")
                Text("Dark").tag("Dark")
            }
            .pickerStyle(.segmented)

            // Blur
            HStack {
                Text("Blur Amount")
                Slider(value: $settings.blurAmount, in: 0...100)
                Text("\(Int(settings.blurAmount))")
                    .frame(width: 40, alignment: .leading)
            }

            Divider()

            // Launcher App
            VStack(alignment: .leading, spacing: 8) {
                Text("Launcher App")

                HStack {
                    Text(settings.launcherBundlePath.isEmpty
                         ? "No app selected"
                         : settings.launcherBundlePath)
                        .font(.caption)

                    Spacer()

                    Button("Choose…") {
                        chooseLauncherApp()
                    }
                }
            }

            Divider()

            // Centering
            Toggle("Center Taskbar Icons", isOn: Binding(
                get: { settings.layoutMode == "Center" },
                set: { settings.layoutMode = $0 ? "Center" : "Left" }
            ))

            Divider()

            // MARK: - Weather Widget Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Weather Widget")
                    .font(.headline)

                Toggle("Enable Weather Widget", isOn: $settings.showWeatherWidget)

                Text("Weather data is provided by Open‑Meteo. When clicked, Apple’s Weather app opens, so live conditions may not match.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            // Quit
            Button("Quit DockBar") {
                showQuitConfirm = true
            }
            .alert("Are you sure you want to quit DockBar?",
                   isPresented: $showQuitConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Quit", role: .destructive) {
                    NSApp.terminate(nil)
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 420)
    }

    // MARK: - File Picker

    private func chooseLauncherApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]

        if panel.runModal() == .OK, let url = panel.url {
            settings.launcherBundlePath = url.path
        }
    }
}
