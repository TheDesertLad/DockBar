// File: TaskbarIconStackView.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

final class TaskbarIconStackView: NSStackView, AppIconViewDelegate {

    private let controller = TaskbarItemsController.shared
    private var dragSourceIndex: Int?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureStack()
        registerForDraggedTypes([.string])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureStack()
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

    // MARK: - Build Icons
    func rebuildIcons() {
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

    // MARK: - Hit Testing
    func runningApp(at point: NSPoint) -> NSRunningApplication? {
        for subview in arrangedSubviews {
            guard let iconView = subview as? AppIconView else { continue }

            let localPoint = convert(point, to: iconView)

            if iconView.bounds.contains(localPoint) {
                let bundleID = iconView.item.bundleIdentifier
                return NSWorkspace.shared.runningApplications.first {
                    $0.bundleIdentifier == bundleID
                }
            }
        }
        return nil
    }

    // MARK: - Drag Delegate (AppIconViewDelegate)

    func appIconViewDidBeginDrag(_ view: AppIconView, item: AppItem, index: Int) {
        // Prevent dragging launcher
        if item.bundleIdentifier == controller.lastLauncherBundleID {
            dragSourceIndex = nil
            return
        }
        dragSourceIndex = index
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .move
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let sourceIndex = dragSourceIndex else { return .move }

        let location = sender.draggingLocation
        let dropIndex = TaskbarDragController.shared.indexForDrop(in: self, at: location)

        controller.movePinnedItem(from: sourceIndex, to: dropIndex)
        dragSourceIndex = dropIndex

        return .move
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        dragSourceIndex = nil
    }

    // MARK: - AppIconViewDelegate actions

    func appIconViewDidRequestActivate(_ view: AppIconView, item: AppItem) {
        if let running = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == item.bundleIdentifier
        }) {
            running.activate(options: [.activateAllWindows])
        } else {
            NSWorkspace.shared.open(item.bundleURL)
        }
    }

    func appIconViewDidRequestPin(_ view: AppIconView, item: AppItem) {
        controller.pinApp(bundleID: item.bundleIdentifier, path: item.bundleURL.path)
    }

    func appIconViewDidRequestUnpin(_ view: AppIconView, item: AppItem) {
        // Prevent unpinning launcher
        if item.bundleIdentifier == controller.lastLauncherBundleID {
            return
        }
        controller.unpinApp(bundleID: item.bundleIdentifier)
    }

    func appIconViewDidRequestQuit(_ view: AppIconView, item: AppItem) {
        if let running = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == item.bundleIdentifier
        }) {
            running.terminate()
        }
    }

    // This was in your earlier version and is required by the protocol
    func appIconViewIsLauncher(_ view: AppIconView) -> Bool {
        return view.item.bundleIdentifier == controller.lastLauncherBundleID
    }

    func moveIcon(from oldIndex: Int, to newIndex: Int) {
        controller.movePinnedItem(from: oldIndex, to: newIndex)
    }
}
