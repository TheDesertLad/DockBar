//File: TaskbarWindow.swift
//This was built using Microsoft Copilot

import AppKit
import Combine

class TaskbarWindow: NSWindow {

    static let baseHeightPoints: CGFloat = 48
    private var cancellables = Set<AnyCancellable>()
    private var taskbarView: TaskbarView!

    // MARK: - Init
    convenience init() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let frame = TaskbarWindow.computeFrame(for: screen)

        self.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        configure()
        setupAppearanceObserver()
        setupBlurObserver()
    }

    // MARK: - Window Setup
    private func configure() {
        backgroundColor = .clear
        isOpaque = false

        level = .statusBar
        ignoresMouseEvents = false

        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary
        ]

        isMovable = false
        isMovableByWindowBackground = false

        // Install vibrant view
        taskbarView = TaskbarView(frame: contentView!.bounds)
        taskbarView.autoresizingMask = [.width, .height]
        self.contentView = taskbarView
    }

    // MARK: - Frame Calculation
    static func computeFrame(for screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let heightInPoints = baseHeightPoints

        return NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: screenFrame.width,
            height: heightInPoints
        )
    }

    // MARK: - Appearance Handling
    private func setupAppearanceObserver() {
        TaskbarSettings.shared.$appearance
            .sink { [weak self] newValue in
                self?.applyAppearance(newValue)
            }
            .store(in: &cancellables)

        applyAppearance(TaskbarSettings.shared.appearance)
    }

    private func applyAppearance(_ mode: String) {
        switch mode {
        case "Dark":
            contentView?.appearance = NSAppearance(named: .darkAqua)

        case "Light":
            contentView?.appearance = NSAppearance(named: .aqua)

        default: // System Preferences
            contentView?.appearance = nil
        }

        contentView?.needsDisplay = true
    }

    // MARK: - Blur Handling
    private func setupBlurObserver() {
        TaskbarSettings.shared.$blurAmount
            .sink { [weak self] newValue in
                self?.taskbarView.updateBlur(intensity: newValue)
            }
            .store(in: &cancellables)

        taskbarView.updateBlur(intensity: TaskbarSettings.shared.blurAmount)
    }

    // MARK: - Right Click Menu
    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        // --- Activity Monitor ---
        let activityItem = NSMenuItem(
            title: "Activity Monitor",
            action: #selector(openActivityMonitor),
            keyEquivalent: ""
        )
        activityItem.target = self

        // Load Activity Monitor icon
        if let icon = NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Activity Monitor.app") as NSImage? {
            icon.size = NSSize(width: 16, height: 16)
            activityItem.image = icon
        }

        menu.addItem(activityItem)

        // --- Divider ---
        menu.addItem(NSMenuItem.separator())

        // --- Taskbar Settings ---
        let settingsItem = NSMenuItem(
            title: "Taskbar Settings",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self

        // Standard gear icon
        settingsItem.image = NSImage(named: NSImage.actionTemplateName)

        menu.addItem(settingsItem)

        NSMenu.popUpContextMenu(menu, with: event, for: self.contentView!)
    }

    // MARK: - Menu Actions
    @objc private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.open(url)
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }
}
