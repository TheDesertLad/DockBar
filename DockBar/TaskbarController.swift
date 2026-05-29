//File: TaskbarController.swift
//This was built using Microsoft Copilot

import AppKit

class TaskbarController {
    private var window: TaskbarWindow?

    init() {
        window = TaskbarWindow()

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

        let newMain = NSScreen.main ?? NSScreen.screens.first!
        let newFrame = TaskbarWindow.computeFrame(for: newMain)

        window.setFrame(newFrame, display: true)
    }
}

