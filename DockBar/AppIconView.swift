// File: AppIconView.swift
// This was built using Microsoft Copilot

import AppKit

protocol AppIconViewDelegate: AnyObject {
    func appIconViewDidRequestActivate(_ view: AppIconView, item: AppItem)
    func appIconViewDidRequestPin(_ view: AppIconView, item: AppItem)
    func appIconViewDidRequestUnpin(_ view: AppIconView, item: AppItem)
    func appIconViewDidRequestQuit(_ view: AppIconView, item: AppItem)
    func appIconViewIsLauncher(_ view: AppIconView) -> Bool

    // Drag support
    func appIconViewDidBeginDrag(_ view: AppIconView, item: AppItem, index: Int)
}

final class AppIconView: NSView {

    weak var delegate: AppIconViewDelegate?
    var item: AppItem {
        didSet { updateContent() }
    }

    // Layout
    private let hoverPlateView = NSVisualEffectView()
    private let imageView = NSImageView()
    private let indicatorView = NSView()

    // Hover
    private var trackingArea: NSTrackingArea?
    private var isHovering = false

    // Drag
    var indexInStack: Int = 0

    override var intrinsicContentSize: NSSize {
        NSSize(width: 48, height: 48)
    }

    init(item: AppItem) {
        self.item = item
        super.init(frame: NSRect(x: 0, y: 0, width: 48, height: 48))
        setupViews()
        updateContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        wantsLayer = true

        hoverPlateView.material = .menu
        hoverPlateView.blendingMode = .withinWindow
        hoverPlateView.state = .inactive
        hoverPlateView.wantsLayer = true
        hoverPlateView.layer?.cornerRadius = 10
        hoverPlateView.alphaValue = 0.0

        addSubview(hoverPlateView)
        hoverPlateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hoverPlateView.widthAnchor.constraint(equalToConstant: 48),
            hoverPlateView.heightAnchor.constraint(equalToConstant: 48),
            hoverPlateView.centerXAnchor.constraint(equalTo: centerXAnchor),
            hoverPlateView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2)
        ])

        indicatorView.wantsLayer = true
        indicatorView.layer?.cornerRadius = 1.5
        indicatorView.isHidden = true
        addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicatorView.widthAnchor.constraint(equalToConstant: 24),
            indicatorView.heightAnchor.constraint(equalToConstant: 3),
            indicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
    }

    private func updateContent() {
        imageView.image = item.icon
        indicatorView.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        indicatorView.isHidden = !item.isRunning
    }

    // MARK: - Hover

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        animateHover(hovering: true)
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        animateHover(hovering: false)
    }

    private func animateHover(hovering: Bool) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            hoverPlateView.animator().alphaValue = hovering ? 1.0 : 0.0
        }
    }

    // MARK: - Mouse / Drag

    override func mouseDown(with event: NSEvent) {
        guard event.type == .leftMouseDown else { return }

        window?.trackEvents(
            matching: [.leftMouseDragged, .leftMouseUp],
            timeout: TimeInterval.infinity,
            mode: .eventTracking
        ) { dragEvent, stop in
            guard let dragEvent = dragEvent else {
                stop.pointee = true
                return
            }

            switch dragEvent.type {
            case .leftMouseDragged:
                self.beginDragSession(with: dragEvent)
                stop.pointee = true
            case .leftMouseUp:
                self.delegate?.appIconViewDidRequestActivate(self, item: self.item)
                stop.pointee = true
            default:
                break
            }
        }
    }

    private func beginDragSession(with event: NSEvent) {
        delegate?.appIconViewDidBeginDrag(self, item: item, index: indexInStack)

        let draggingImage = imageView.image ?? NSImage(size: NSSize(width: 40, height: 40))
        let draggingItem = NSDraggingItem(pasteboardWriter: NSString(string: item.bundleIdentifier))
        draggingItem.setDraggingFrame(bounds, contents: draggingImage)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    override func rightMouseDown(with event: NSEvent) {
        showContextMenu()
    }

    // MARK: - Context Menu

    private func showContextMenu() {
        if delegate?.appIconViewIsLauncher(self) == true {
            let menu = NSMenu()

            menu.addItem(makeSystemItem(title: "Disk Utility",
                                        bundleID: "com.apple.DiskUtility",
                                        path: "/System/Applications/Utilities/Disk Utility.app"))
            menu.addItem(makeSystemItem(title: "Terminal",
                                        bundleID: "com.apple.Terminal",
                                        path: "/System/Applications/Utilities/Terminal.app"))

            menu.addItem(NSMenuItem.separator())

            menu.addItem(makeSystemItem(title: "Activity Monitor",
                                        bundleID: "com.apple.ActivityMonitor",
                                        path: "/System/Applications/Utilities/Activity Monitor.app"))
            menu.addItem(makeSystemItem(title: "System Settings",
                                        bundleID: "com.apple.systempreferences",
                                        path: "/System/Applications/System Settings.app"))
            menu.addItem(makeSystemItem(title: "Finder",
                                        bundleID: "com.apple.finder",
                                        path: "/System/Library/CoreServices/Finder.app"))
            menu.addItem(makeSystemItem(title: "Spotlight",
                                        bundleID: "com.apple.Spotlight",
                                        path: "/System/Library/CoreServices/Spotlight.app"))

            NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent ?? NSEvent(), for: self)
        } else {
            let menu = NSMenu()

            if item.isPinned {
                let unpin = NSMenuItem(title: "Unpin from Taskbar", action: #selector(unpinAction), keyEquivalent: "")
                unpin.target = self
                menu.addItem(unpin)
            } else {
                let pin = NSMenuItem(title: "Pin to Taskbar", action: #selector(pinAction), keyEquivalent: "")
                pin.target = self
                menu.addItem(pin)
            }

            let showInFinder = NSMenuItem(title: "Show in Finder", action: #selector(showInFinderAction), keyEquivalent: "")
            showInFinder.target = self
            menu.addItem(showInFinder)

            if item.isRunning {
                let quit = NSMenuItem(title: "Quit", action: #selector(quitAction), keyEquivalent: "")
                quit.target = self
                menu.addItem(quit)
            }

            NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent ?? NSEvent(), for: self)
        }
    }

    private func makeSystemItem(title: String, bundleID: String, path: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(systemToolAction(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = ["bundleID": bundleID, "path": path]
        item.image = NSWorkspace.shared.icon(forFile: path)
        item.image?.size = NSSize(width: 16, height: 16)
        return item
    }

    // MARK: - Actions

    @objc private func pinAction() {
        delegate?.appIconViewDidRequestPin(self, item: item)
    }

    @objc private func unpinAction() {
        delegate?.appIconViewDidRequestUnpin(self, item: item)
    }

    @objc private func quitAction() {
        // Delegate handles NSRunningApplication.terminate / forceTerminate
        delegate?.appIconViewDidRequestQuit(self, item: item)
    }

    @objc private func showInFinderAction() {
        NSWorkspace.shared.activateFileViewerSelecting([item.bundleURL])
    }

    @objc private func systemToolAction(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? [String: String] else { return }
        let bundleID = info["bundleID"]
        let path = info["path"]

        if let bundleID = bundleID,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {

            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, _ in }
            return
        }

        if let path = path {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }
}

// MARK: - NSDraggingSource

extension AppIconView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession,
                         sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }

    func draggingSession(_ session: NSDraggingSession,
                         endedAt screenPoint: NSPoint,
                         operation: NSDragOperation) {
        // No-op for now
    }
}
