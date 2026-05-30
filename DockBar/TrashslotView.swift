// File: TrashslotView.swift
// Updated by Microsoft Copilot

import AppKit

final class TrashslotView: NSView {

    private let label = NSTextField(labelWithString: "Drag Here to Discard")

    // Undo support
    private var lastOriginalURL: URL?
    private var lastTrashedURL: URL?

    // Internal drag states
    private var isDraggingOver = false {
        didSet { needsDisplay = true }
    }

    private var isDraggingSomething = false {
        didSet {
            if !isDraggingOver {
                label.stringValue = "Drag Here to Discard"
                label.textColor = .secondaryLabelColor
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

    // MARK: - External Drag Notifications

    func beginExternalDrag() {
        if !isDraggingOver {
            isDraggingSomething = true
            label.stringValue = "Drag Here to Discard"
        }
    }

    func endExternalDrag() {
        isDraggingSomething = false
        if !isDraggingOver {
            label.stringValue = "Drag Here to Discard"
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let wallHeight: CGFloat = 40
        let top: CGFloat = (bounds.height - wallHeight) / 2
        let bottom: CGFloat = top + wallHeight

        let leftX: CGFloat = 0
        let rightX: CGFloat = bounds.width

        let path = NSBezierPath()
        path.lineWidth = 1

        if effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            NSColor.white.setStroke()
        } else {
            NSColor.black.setStroke()
        }

        path.move(to: NSPoint(x: leftX + 0.5, y: top))
        path.line(to: NSPoint(x: leftX + 0.5, y: bottom))

        path.move(to: NSPoint(x: rightX - 0.5, y: top))
        path.line(to: NSPoint(x: rightX - 0.5, y: bottom))

        path.stroke()

        if isDraggingOver {
            NSColor.systemRed.withAlphaComponent(0.25).setFill()
            let rect = bounds.insetBy(dx: 4, dy: 6)
            NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8).fill()
        }
    }

    // MARK: - Drag Handling

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        isDraggingSomething = true
        isDraggingOver = true

        label.stringValue = "Release to Discard"
        label.textColor = .systemRed

        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        isDraggingSomething = true
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDraggingOver = false

        label.stringValue = "Drag Here to Discard"
        label.textColor = .secondaryLabelColor
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDraggingOver = false
        isDraggingSomething = false

        label.stringValue = "Drag Here to Discard"
        label.textColor = .secondaryLabelColor

        guard let urls =
                sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]
        else { return false }

        for url in urls {
            var trashedURL: NSURL?
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: &trashedURL)

                // Save undo info
                lastOriginalURL = url
                lastTrashedURL = trashedURL as URL?
            } catch {
                print("Trash error: \(error)")
            }
        }

        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        isDraggingSomething = false
        isDraggingOver = false

        label.stringValue = "Drag Here to Discard"
        label.textColor = .secondaryLabelColor
    }

    // MARK: - Right Click Menu

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        let openItem = NSMenuItem(
            title: "Open Trash",
            action: #selector(openTrash),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        let undoItem = NSMenuItem(
            title: "Undo Move",
            action: #selector(undoMove),
            keyEquivalent: ""
        )
        undoItem.target = self
        undoItem.isEnabled = (lastOriginalURL != nil && lastTrashedURL != nil)
        menu.addItem(undoItem)

        menu.addItem(NSMenuItem.separator())

        let emptyItem = NSMenuItem(
            title: "Empty Trash…",
            action: #selector(emptyTrash),
            keyEquivalent: ""
        )
        emptyItem.target = self
        menu.addItem(emptyItem)

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func openTrash() {
        if let url = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func undoMove() {
        guard let original = lastOriginalURL,
              let trashed = lastTrashedURL else { return }

        do {
            try FileManager.default.moveItem(at: trashed, to: original)
        } catch {
            print("Undo failed: \(error)")
        }

        lastOriginalURL = nil
        lastTrashedURL = nil
    }

    @objc private func emptyTrash() {
        let script = """
        tell application "Finder"
            empty the trash
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
}

