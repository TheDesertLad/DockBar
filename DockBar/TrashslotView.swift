// File: TrashslotView.swift
// This was built using Microsoft Copilot

import AppKit

final class TrashslotView: NSView {

    private let label = NSTextField(labelWithString: "Trash")

    // Internal drag states
    private var isDraggingOver = false {
        didSet { needsDisplay = true }
    }

    private var isDraggingSomething = false {
        didSet {
            if !isDraggingOver {
                label.stringValue = isDraggingSomething ? "Drop Here to Discard" : "Trash"
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        registerForDraggedTypes([.fileURL])
    }

    private func setupView() {
        wantsLayer = true

        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.alignment = .center
        label.textColor = .secondaryLabelColor

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 140, height: 48)
    }

    // MARK: - External Drag Notifications (from TaskbarView)

    func beginExternalDrag() {
        if !isDraggingOver {
            isDraggingSomething = true
            label.stringValue = "Drop Here to Discard"
        }
    }

    func endExternalDrag() {
        isDraggingSomething = false
        if !isDraggingOver {
            label.stringValue = "Trash"
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Taskbar height = 48, icon height = 40
        let wallHeight: CGFloat = 40
        let top: CGFloat = (bounds.height - wallHeight) / 2   // = 4
        let bottom: CGFloat = top + wallHeight                // = 44

        let leftX: CGFloat = 0
        let rightX: CGFloat = bounds.width

        let path = NSBezierPath()
        path.lineWidth = 1

        // Divider color
        if effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            NSColor.white.setStroke()
        } else {
            NSColor.black.setStroke()
        }

        // Left wall
        path.move(to: NSPoint(x: leftX + 0.5, y: top))
        path.line(to: NSPoint(x: leftX + 0.5, y: bottom))

        // Right wall
        path.move(to: NSPoint(x: rightX - 0.5, y: top))
        path.line(to: NSPoint(x: rightX - 0.5, y: bottom))

        path.stroke()

        // Hover highlight (RED)
        if isDraggingOver {
            NSColor.systemRed.withAlphaComponent(0.25).setFill()
            let rect = bounds.insetBy(dx: 4, dy: 6)
            NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8).fill()
        }
    }

    // MARK: - Drag Handling (inside Trashslot)

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        isDraggingSomething = true
        isDraggingOver = true
        label.stringValue = "Release to Discard"
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        isDraggingSomething = true
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDraggingOver = false
        label.stringValue = isDraggingSomething ? "Drop Here to Discard" : "Trash"
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDraggingOver = false
        isDraggingSomething = false
        label.stringValue = "Trash"

        guard let urls =
                sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]
        else { return false }

        for url in urls {
            try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
        }
        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        isDraggingSomething = false
        isDraggingOver = false
        label.stringValue = "Trash"
    }
}
