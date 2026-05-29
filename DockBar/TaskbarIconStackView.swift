// File: TaskbarIconStackView.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

final class TaskbarIconStackView: NSStackView, AppIconViewDelegate {

    private var cancellables = Set<AnyCancellable>()
    private let controller = TaskbarItemsController.shared

    private var dragSourceIndex: Int?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureStack()
        setupObservers()
        registerForDraggedTypes([.string])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureStack()
        setupObservers()
        registerForDraggedTypes([.string])
    }

    // MARK: - StackView Configuration
    private func configureStack() {
        orientation = .horizontal
        alignment = .centerY
        spacing = 6

        distribution = .gravityAreas
        edgeInsets = NSEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        detachesHiddenViews = false

        translatesAutoresizingMaskIntoConstraints = false
        setHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    // MARK: - Observers
    private func setupObservers() {
        controller.$finalItems
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildIcons()
            }
            .store(in: &cancellables)
    }

    // MARK: - Build Icons
    private func rebuildIcons() {
        arrangedSubviews.forEach { view in
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for (index, item) in controller.finalItems.enumerated() {
            let iconView = AppIconView(item: item)
            iconView.delegate = self
            iconView.indexInStack = index

            iconView.widthAnchor.constraint(equalToConstant: 48).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 48).isActive = true

            addArrangedSubview(iconView)
        }
    }

    // MARK: - Drag Delegate

    func appIconViewDidBeginDrag(_ view: AppIconView, item: AppItem, index: Int) {
        dragSourceIndex = index
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .move
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let sourceIndex = dragSourceIndex else { return .move }

        let location = sender.draggingLocation
        let dropIndex = TaskbarDragController.shared.indexForDrop(in: self, at: location)

        if dropIndex != sourceIndex {
            controller.movePinnedItem(from: sourceIndex, to: dropIndex)
            dragSourceIndex = dropIndex
        }

        return .move
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        dragSourceIndex = nil
    }

    // MARK: - AppIconViewDelegate

    func appIconViewDidRequestActivate(_ view: AppIconView, item: AppItem) {

        guard let running = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == item.bundleIdentifier
        }) else {
            // App not running → launch it
            NSWorkspace.shared.open(item.bundleURL)
            return
        }

        // 🔥 FIX: Unminimize windows using Accessibility API
        let appElement = AXUIElementCreateApplication(running.processIdentifier)

        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &value
        )

        if result == .success, let windows = value as? [AXUIElement] {
            for window in windows {
                var minimized: AnyObject?
                if AXUIElementCopyAttributeValue(
                    window,
                    kAXMinimizedAttribute as CFString,
                    &minimized
                ) == .success,
                   let isMinimized = minimized as? Bool,
                   isMinimized == true {

                    AXUIElementSetAttributeValue(
                        window,
                        kAXMinimizedAttribute as CFString,
                        kCFBooleanFalse
                    )
                }
            }
        }

        // 🔥 FIX: Modern activation API (macOS 14+ safe)
        running.activate(options: [.activateAllWindows])
    }

    func appIconViewDidRequestPin(_ view: AppIconView, item: AppItem) {
        controller.pinApp(bundleID: item.bundleIdentifier, path: item.bundleURL.path)
    }

    func appIconViewDidRequestUnpin(_ view: AppIconView, item: AppItem) {
        controller.unpinApp(bundleID: item.bundleIdentifier)
    }

    func appIconViewDidRequestQuit(_ view: AppIconView, item: AppItem) {
        if let running = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == item.bundleIdentifier
        }) {

            running.terminate()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !running.isTerminated {
                    running.forceTerminate()
                }
            }
        }
    }

    func appIconViewIsLauncher(_ view: AppIconView) -> Bool {
        let launcherPath = TaskbarSettings.shared.launcherBundlePath
        return view.item.bundleURL.path == launcherPath
    }

    func moveIcon(from oldIndex: Int, to newIndex: Int) {
        controller.movePinnedItem(from: oldIndex, to: newIndex)
    }
}

