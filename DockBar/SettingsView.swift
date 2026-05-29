// File: SettingsView.swift
// This was built using Microsoft Copilot

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = TaskbarSettings.shared

    var body: some View {
        ScrollView {   // <-- ENABLE SCROLLING
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

                // Quit Button
                Button("Quit DockBar") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)
            }
            .padding(20)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

