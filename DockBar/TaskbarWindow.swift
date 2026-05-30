// File: TaskbarWindow.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

final class TaskbarWindow: NSWindow {

    // Controller reference (set by TaskbarController)
    weak var controller: TaskbarController?

    private let taskbarView = TaskbarView()
    private let visualEffect = NSVisualEffectView()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Designated Initializer
    init(screen: NSScreen) {
        let height: CGFloat = 48
        let frame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY,
            width: screen.frame.width,
            height: height
        )

        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.setFrame(frame, display: true)
        configureWindow()
        bindItems()
        bindSettings()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("TaskbarWindow does not support init(coder:)")
    }

    // MARK: - Setup

    private func configureWindow() {
        isOpaque = false
        backgroundColor = .clear
        level = .statusBar

        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        ignoresMouseEvents = false

        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.material = .sidebar
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active

        contentView = NSView(frame: frame)
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.clear.cgColor

        if let contentView = contentView {
            contentView.addSubview(visualEffect)

            NSLayoutConstraint.activate([
                visualEffect.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                visualEffect.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                visualEffect.topAnchor.constraint(equalTo: contentView.topAnchor),
                visualEffect.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

            visualEffect.addSubview(taskbarView)
            taskbarView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                taskbarView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
                taskbarView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
                taskbarView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
                taskbarView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor)
            ])
        }
    }

    // MARK: - Bind items (finalItems → icons)

    private func bindItems() {
        TaskbarItemsController.shared.$finalItems
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.taskbarView.reloadIcons()
            }
            .store(in: &cancellables)
    }

    // MARK: - Settings Bindings

    private func bindSettings() {
        let settings = TaskbarSettings.shared

        settings.$appearance
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.applyAppearance(value)
            }
            .store(in: &cancellables)

        settings.$blurAmount
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.applyBlur(value)
            }
            .store(in: &cancellables)
    }

    private func applyAppearance(_ value: String) {
        switch value {
        case "Dark":
            visualEffect.appearance = NSAppearance(named: .darkAqua)
        case "Light":
            visualEffect.appearance = NSAppearance(named: .aqua)
        default:
            visualEffect.appearance = nil // follow system
        }
    }

    private func applyBlur(_ value: Double) {
        let clamped = max(0, min(100, value))

        switch clamped {
        case 0..<25:
            visualEffect.material = .titlebar
        case 25..<50:
            visualEffect.material = .underWindowBackground
        case 50..<75:
            visualEffect.material = .sidebar
        default:
            visualEffect.material = .hudWindow
        }
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // MARK: - Right Click Handling

    override func rightMouseDown(with event: NSEvent) {
        guard let controller = controller else { return }

        let location = convertPoint(fromScreen: event.locationInWindow)

        if let app = taskbarView.runningApp(at: location) {
            controller.showContextMenu(for: app, at: location)
        }
    }
}
