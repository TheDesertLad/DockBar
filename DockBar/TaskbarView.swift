// File: TaskbarView.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

final class TaskbarView: NSView {

    private let stackView = TaskbarIconStackView()
    private var centerConstraint: NSLayoutConstraint?
    private var cancellables = Set<AnyCancellable>()

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

    // MARK: - Layout Fix
    private func setupView() {
        wantsLayer = true

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        stackView.setHuggingPriority(.defaultLow, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    // MARK: - Centering Logic
    private func setupObservers() {
        TaskbarItemsController.shared.$shouldCenter
            .receive(on: RunLoop.main)
            .sink { [weak self] shouldCenter in
                self?.updateAlignment(centered: shouldCenter)
            }
            .store(in: &cancellables)
    }

    private func updateAlignment(centered: Bool) {
        if let c = centerConstraint {
            removeConstraint(c)
            centerConstraint = nil
        }

        if centered {
            NSLayoutConstraint.deactivate(
                constraints.filter { $0.firstAttribute == .leading }
            )

            let c = stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
            c.isActive = true
            centerConstraint = c
        } else {
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
            ])
        }

        layoutSubtreeIfNeeded()
    }

    // MARK: - Taskbar Context Menu (empty space)

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        let activity = NSMenuItem(
            title: "Activity Monitor",
            action: #selector(openActivityMonitor),
            keyEquivalent: ""
        )
        activity.target = self
        menu.addItem(activity)

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
        // Modern macOS-safe API
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in }
        }
    }

    @objc private func openSettings() {
        // FIX: Correct class name
        SettingsWindowController.shared.show()
    }

    // MARK: - Drag from Finder (drop to pin)

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: .fileURL) as? String ??
                sender.draggingPasteboard.string(forType: .fileURL) else {
            return handleMultipleURLs(sender)
        }

        if let url = URL(string: pasteboard) {
            handleDroppedURLs([url], sender: sender)
            return true
        }
        return false
    }

    private func handleMultipleURLs(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }
        handleDroppedURLs(urls, sender: sender)
        return true
    }

    private func handleDroppedURLs(_ urls: [URL], sender: NSDraggingInfo) {
        let location = sender.draggingLocation
        let dropIndex = TaskbarDragController.shared.indexForDrop(in: stackView, at: location)

        for url in urls {
            guard let appURL = resolveAppURL(from: url) else { continue }
            guard appURL.pathExtension == "app" else { continue }

            if let bundle = Bundle(url: appURL),
               let id = bundle.bundleIdentifier {

                var pinned = PinnedAppsManager.shared.loadPinnedApps()

                if !pinned.contains(where: { $0.bundleID == id }) {
                    let clampedIndex = max(0, min(dropIndex, pinned.count))
                    pinned.insert((bundleID: id, path: appURL.path), at: clampedIndex)
                    PinnedAppsManager.shared.savePinnedApps(pinned)
                    TaskbarItemsController.shared.pinApp(bundleID: id, path: appURL.path)
                }
            }
        }
    }

    private func resolveAppURL(from url: URL) -> URL? {
        if url.pathExtension == "app" {
            return url
        }

        do {
            let values = try url.resourceValues(forKeys: [.isAliasFileKey])
            if values.isAliasFile == true {
                let resolved = try URL(resolvingAliasFileAt: url)
                if resolved.pathExtension == "app" {
                    return resolved
                }
            }
        } catch {
            return nil
        }

        return nil
    }
}
