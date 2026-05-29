import SwiftUI
import AppKit

struct SettingsView: View {

    @ObservedObject private var settings = TaskbarSettings.shared
    @State private var showQuitConfirmation = false

    // FIX: Local state mirror for launcher position
    @State private var tempLauncherPosition = TaskbarSettings.shared.launcherPosition

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                appearanceSection
                blurSection
                launcherSection
                quitSection

                Spacer()
            }
            .padding(20)
        }
        .frame(width: 420, height: 520)
        .alert("Are you sure?", isPresented: $showQuitConfirmation) {
            Button("Quit", role: .destructive) {
                NSApp.terminate(nil)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you really want to close DockBar?")
        }
    }

    private var appearanceSection: some View {
        GroupBox(label: Text("Appearance").font(.headline)) {
            Picker("Taskbar Appearance", selection: $settings.appearance) {
                Text("System").tag("System")
                Text("Light").tag("Light")
                Text("Dark").tag("Dark")
            }
            .pickerStyle(.radioGroup)
            .padding(.top, 4)
        }
    }

    private var blurSection: some View {
        GroupBox(label: Text("Blur").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Blur Intensity")
                Slider(value: $settings.blurAmount, in: 0...100)
            }
            .padding(.top, 4)
        }
    }

    private var launcherSection: some View {
        GroupBox(label: Text("Launcher App").font(.headline)) {
            VStack(alignment: .leading, spacing: 14) {

                Toggle("Enable Launcher Button", isOn: $settings.launcherEnabled)

                if settings.launcherEnabled {
                    Divider().padding(.vertical, 4)

                    HStack(spacing: 12) {
                        launcherIcon
                        VStack(alignment: .leading) {
                            Text(launcherAppName)
                                .font(.system(size: 14, weight: .medium))
                            Text(settings.launcherAppPath)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Button("Choose Launcher App…") {
                        LauncherPickerWindow.openPicker()
                    }
                    .padding(.top, 6)

                    // MARK: - FIXED LAUNCHER POSITION PICKER
                    Picker("Launcher Position", selection: $tempLauncherPosition) {
                        Text("Left").tag("Left")
                        Text("Center").tag("Center")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: tempLauncherPosition) { newValue in
                        DispatchQueue.main.async {
                            settings.launcherPosition = newValue
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.top, 4)
        }
    }

    private var quitSection: some View {
        GroupBox(label: Text("Close DockBar").font(.headline)) {
            Button(role: .destructive) {
                showQuitConfirmation = true
            } label: {
                Text("Quit")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.top, 4)
        }
    }

    private var launcherIcon: some View {
        let path = settings.launcherAppPath
        let nsImage = NSWorkspace.shared.icon(forFile: path)
        nsImage.size = NSSize(width: 32, height: 32)

        return Image(nsImage: nsImage)
            .resizable()
            .frame(width: 32, height: 32)
            .cornerRadius(6)
    }

    private var launcherAppName: String {
        let path = settings.launcherAppPath
        return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }
}

