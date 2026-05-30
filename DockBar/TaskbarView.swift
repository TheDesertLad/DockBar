// File: TaskbarView.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

final class TaskbarView: NSView {

    private let stackView = TaskbarIconStackView()
    private let weatherView = WeatherWidgetView()
    private let trashView = TrashslotView()
    private let showDesktopButton = ShowDesktopButton()

    private var centerConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?

    private var weatherLeadingConstraint: NSLayoutConstraint?
    private var weatherCenterConstraint: NSLayoutConstraint?

    private var cancellables = Set<AnyCancellable>()

    // Global drag tracking
    private var trackingArea: NSTrackingArea?
    private var isDraggingSomething = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        setupObservers()
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupObservers()
        registerForDraggedTypes([.fileURL])
    }

    // MARK: - Tracking Area

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .mouseEnteredAndExited,
            .activeAlways,
            .inVisibleRect
        ]

        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func mouseMoved(with event: NSEvent) {
        if event.type == .leftMouseDragged || event.type == .otherMouseDragged {
            if !isDraggingSomething {
                isDraggingSomething = true
                trashView.beginExternalDrag()
            }
        }
    }

    override func mouseExited(with event: NSEvent) {
        if isDraggingSomething {
            isDraggingSomething = false
            trashView.endExternalDrag()
        }
    }

    // MARK: - Setup

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

        leadingConstraint = stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)

        NSLayoutConstraint.activate([
            leadingConstraint!,
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor),

            // Trashslot
            trashView.trailingAnchor.constraint(equalTo: showDesktopButton.leadingAnchor, constant: -8),
            trashView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trashView.widthAnchor.constraint(equalToConstant: 140),
            trashView.heightAnchor.constraint(equalTo: heightAnchor),

            // Show Desktop slit (flush to right edge)
            showDesktopButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            showDesktopButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            showDesktopButton.widthAnchor.constraint(equalToConstant: 4),
            showDesktopButton.heightAnchor.constraint(equalTo: heightAnchor),

            // Weather widget
            weatherView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        weatherLeadingConstraint = weatherView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        weatherCenterConstraint = weatherView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -80)
        weatherLeadingConstraint?.isActive = true
    }

    // MARK: - Observers

    private func setupObservers() {
        let items = TaskbarItemsController.shared
        let settings = TaskbarSettings.shared

        items.$shouldCenter
            .receive(on: RunLoop.main)
            .sink { [weak self] shouldCenter in
                self?.updateAlignment(centered: shouldCenter)
            }
            .store(in: &cancellables)

        items.$finalItems
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.stackView.rebuildIcons()
            }
            .store(in: &cancellables)

        // Weather widget visibility
        settings.$showWeatherWidget
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.weatherView.isHidden = !show
            }
            .store(in: &cancellables)

        items.$weatherWidgetMode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                self?.updateWeatherMode(mode)
            }
            .store(in: &cancellables)

        settings.$showDesktopButtonEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                self?.showDesktopButton.isEnabled = enabled
            }
            .store(in: &cancellables)
    }

    // MARK: - REQUIRED BY TaskbarWindow

    func reloadIcons() {
        stackView.rebuildIcons()
    }

    // MARK: - Alignment

    private func updateAlignment(centered: Bool) {
        centerConstraint?.isActive = false
        leadingConstraint?.isActive = false

        if centered {
            centerConstraint = stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
            centerConstraint?.isActive = true
        } else {
            leadingConstraint?.isActive = true
        }

        layoutSubtreeIfNeeded()
    }

    private func updateWeatherMode(_ mode: WeatherWidgetView.Mode) {
        weatherView.mode = mode

        weatherLeadingConstraint?.isActive = false
        weatherCenterConstraint?.isActive = false

        switch mode {
        case .left:
            weatherLeadingConstraint?.isActive = true
        case .leftOfCenter:
            weatherCenterConstraint?.isActive = true
        }

        layoutSubtreeIfNeeded()
    }

    // MARK: - Running App Hit Test

    func runningApp(at point: NSPoint) -> NSRunningApplication? {
        let localPoint = convert(point, to: stackView)
        return stackView.runningApp(at: localPoint)
    }

    // MARK: - Right Click Menu

    override func rightMouseDown(with event: NSEvent) {
        let clickPoint = convert(event.locationInWindow, from: nil)

        if runningApp(at: clickPoint) != nil { return }
        if weatherView.frame.contains(clickPoint) { return }
        if trashView.frame.contains(clickPoint) { return }
        if showDesktopButton.frame.contains(clickPoint) { return }

        let menu = NSMenu()

        let activity = NSMenuItem(
            title: "Activity Monitor",
            action: #selector(openActivityMonitor),
            keyEquivalent: ""
        )
        activity.target = self

        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 16, height: 16)
            activity.image = icon
        }

        menu.addItem(activity)
        menu.addItem(NSMenuItem.separator())

        let settings = NSMenuItem(
            title: "Taskbar Settings",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settings.target = self
        menu.addItem(settings)

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func openActivityMonitor() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: config)
        }
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }
}

