// File: TaskbarController.swift
// This was built using Microsoft Copilot

import AppKit
import SwiftUI

class TaskbarController: NSObject {
    private var window: TaskbarWindow?
    private var currentRightClickedApp: NSRunningApplication?

    override init() {
        super.init()

        let screen = NSScreen.main ?? NSScreen.screens.first!
        window = TaskbarWindow(screen: screen)
        window?.controller = self

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
        let height: CGFloat = 48
        let newFrame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY,
            width: screen.frame.width,
            height: height
        )

        window.setFrame(newFrame, display: true)
    }

    // MARK: - Context Menu

    func showContextMenu(for app: NSRunningApplication, at point: NSPoint) {
        currentRightClickedApp = app

        let menu = NSMenu()
        menu.addItem(
            withTitle: "Quit",
            action: #selector(quitSelectedApp),
            keyEquivalent: ""
        )

        for item in menu.items {
            item.target = self
        }

        if let contentView = window?.contentView {
            NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: contentView)
        }
    }

    @objc private func quitSelectedApp(_ sender: Any?) {
        guard let app = currentRightClickedApp else { return }
        app.terminate()
    }

    // MARK: - Settings entry point (CUSTOM SETTINGS WINDOW)

    func openSettingsWindow() {
        let controller = SettingsWindowController.shared
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

