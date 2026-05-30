// File: ShowDesktopButton.swift
// This was built using Microsoft Copilot

import AppKit

final class ShowDesktopButton: NSView {

    var isEnabled: Bool = true

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor // invisible
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 4, height: 48)
    }

    // No drawing — invisible slit
    override func draw(_ dirtyRect: NSRect) {}

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        toggleShowDesktop()
    }

    private func toggleShowDesktop() {
        let script = """
        tell application "System Events"
            key code 103 using {control down, command down}
        end tell
        """

        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }
}
