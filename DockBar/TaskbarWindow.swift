// File: TaskbarWindow.swift
// This was built using Microsoft Copilot

import AppKit

final class TaskbarWindow: NSWindow {

    private let taskbarView = TaskbarView()

    // MARK: - Designated Initializer
    init(screen: NSScreen) {
        let height: CGFloat = 48
        let frame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY,
            width: screen.frame.width,
            height: height
        )

        // Use the modern designated initializer
        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Assign the frame (this automatically places the window on the correct screen)
        self.setFrame(frame, display: true)

        configureWindow()
    }

    // MARK: - NSCoder Not Supported
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("TaskbarWindow does not support init(coder:)")
    }

    // MARK: - Shared Setup
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

        // Background blur
        let visualEffect = NSVisualEffectView(frame: contentView?.bounds ?? .zero)
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.material = .sidebar
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active

        contentView = visualEffect

        // Add taskbar view
        visualEffect.addSubview(taskbarView)
        taskbarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            taskbarView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            taskbarView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            taskbarView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            taskbarView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor)
        ])
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

