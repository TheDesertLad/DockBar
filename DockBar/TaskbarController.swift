// File: TaskbarController.swift
// This was built using Microsoft Copilot

import AppKit

class TaskbarController {
    private var window: TaskbarWindow?

    init() {
        // Create the window on the main screen
        let screen = NSScreen.main ?? NSScreen.screens.first!
        window = TaskbarWindow(screen: screen)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateForScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func show() {
        window?.orderFrontRegardless()
    }

    @objc private func updateForScreenChange() {
        guard let window = window else { return }

        let screen = NSScreen.main ?? NSScreen.screens.first!

        // Recompute the frame manually (same logic as TaskbarWindow.init)
        let height: CGFloat = 48
        let newFrame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY,
            width: screen.frame.width,
            height: height
        )

        window.setFrame(newFrame, display: true)
    }
}

