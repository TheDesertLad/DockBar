// File: TaskbarView.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

final class TaskbarView: NSView {

    private let stackView = TaskbarIconStackView()
    private let weatherView = WeatherWidgetView()   // Anchored mode only
    private let trashView = TrashslotView()
    private let showDesktopButton = ShowDesktopButton()

    private var centerConstraint: NSLayoutConstraint?
    private var stackLeadingConstraint: NSLayoutConstraint?

    private var cancellables = Set<AnyCancellable>()
    private var alignmentDebounce: AnyCancellable?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        setupObservers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupObservers()
    }

    private func setupView() {
        wantsLayer = true

        addSubview(stackView)
        addSubview(weatherView)
        addSubview(trashView)
        addSubview(showDesktopButton)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        weatherView.translatesAutoresizingMaskIntoConstraints = false
        trashView.translatesAutoresizingMaskIntoConstraints = false
        showDesktopButton.translatesAutoresizingMaskIntoConstraints = false

        stackLeadingConstraint = stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        stackLeadingConstraint?.isActive = true

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor),

            weatherView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            weatherView.centerYAnchor.constraint(equalTo: centerYAnchor),

            trashView.trailingAnchor.constraint(equalTo: showDesktopButton.leadingAnchor, constant: -8),
            trashView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trashView.widthAnchor.constraint(equalToConstant: 140),
            trashView.heightAnchor.constraint(equalTo: heightAnchor),

            showDesktopButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            showDesktopButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            showDesktopButton.widthAnchor.constraint(equalToConstant: 4),
            showDesktopButton.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        weatherView.onRequestDisable = {
            TaskbarSettings.shared.showWeatherWidget = false
        }
    }

    private func setupObservers() {
        let items = TaskbarItemsController.shared
        let settings = TaskbarSettings.shared

        items.$finalItems
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.stackView.rebuildIcons()
            }
            .store(in: &cancellables)

        items.$weatherWidgetMode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                self?.weatherView.mode = mode
            }
            .store(in: &cancellables)

        items.$shouldCenter
            .receive(on: RunLoop.main)
            .sink { [weak self] centered in
                self?.debouncedAlignmentUpdate(centered: centered)
            }
            .store(in: &cancellables)

        settings.$showWeatherWidget
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.debouncedAlignmentUpdate(centered: items.shouldCenter)
            }
            .store(in: &cancellables)
    }

    private func debouncedAlignmentUpdate(centered: Bool) {
        alignmentDebounce?.cancel()

        alignmentDebounce = Just(centered)
            .delay(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] centered in
                self?.updateAlignment(centered: centered)
            }
    }

    private func updateAlignment(centered: Bool) {
        let settings = TaskbarSettings.shared

        centerConstraint?.isActive = false
        stackLeadingConstraint?.isActive = false

        if centered {
            weatherView.isHidden = !settings.showWeatherWidget
            centerConstraint = stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
            centerConstraint?.isActive = true
        } else {
            weatherView.isHidden = true
            stackLeadingConstraint?.isActive = true
        }

        layoutSubtreeIfNeeded()
    }

    func reloadIcons() {
        stackView.rebuildIcons()
    }

    func runningApp(at point: NSPoint) -> NSRunningApplication? {
        return stackView.runningApp(at: point)
    }

    // MARK: - Launcher Hit Zone

    private func isLeftLayoutWithLauncher() -> Bool {
        let settings = TaskbarSettings.shared
        return settings.layoutMode == "Left"
            && settings.launcherEnabled
            && TaskbarItemsController.shared.shouldCenter == false
    }

    private func launcherHitZoneContains(_ location: NSPoint) -> Bool {
        guard isLeftLayoutWithLauncher() else { return false }

        let stackFrame = stackView.frame
        let maxX = stackFrame.minX + 48.0

        return location.x >= 0 &&
               location.x <= maxX &&
               location.y >= stackFrame.minY &&
               location.y <= stackFrame.maxY
    }

    private func launcherView() -> AppIconView? {
        stackView.launcherIconView()
    }

    // MARK: - Left Click

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        if launcherHitZoneContains(location),
           let launcher = launcherView() {
            stackView.appIconViewDidRequestActivate(launcher, item: launcher.item)
            return
        }

        super.mouseDown(with: event)
    }

    // MARK: - Right Click

    override func rightMouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        if launcherHitZoneContains(location),
           let launcher = launcherView() {
            launcher.rightMouseDown(with: event)
            return
        }

        // Prevent phantom icons when centered
        if TaskbarItemsController.shared.shouldCenter == false,
           let _ = stackView.runningApp(at: location) {
            super.rightMouseDown(with: event)
            return
        }

        showDeadSpaceMenu(at: location)
    }

    private func showDeadSpaceMenu(at point: NSPoint) {
        let menu = NSMenu()

        let activityItem = NSMenuItem(
            title: "Activity Monitor",
            action: #selector(openActivityMonitor),
            keyEquivalent: ""
        )
        activityItem.target = self
        menu.addItem(activityItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Taskbar Settings",
            action: #selector(openTaskbarSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: self)
    }

    @objc private func openActivityMonitor() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: config)
        }
    }

    @objc private func openTaskbarSettings() {
        (window as? TaskbarWindow)?.openSettings()
    }
}

