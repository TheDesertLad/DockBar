// File: TaskbarIconStackView.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

extension Notification.Name {
    static let taskbarDragBegan = Notification.Name("TaskbarDragBegan")
    static let taskbarDragMoved = Notification.Name("TaskbarDragMoved")
    static let taskbarDragEnded = Notification.Name("TaskbarDragEnded")
}

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

    private func configureStack() {
        orientation = .horizontal
        alignment = .centerY

        // REMOVE GAPS BETWEEN ICONS
        spacing = 0

        distribution = .gravityAreas
        edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        detachesHiddenViews = false
        translatesAutoresizingMaskIntoConstraints = false
        setHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    // MARK: - Rebuild Icons

    func rebuildIcons() {
        arrangedSubviews.forEach { view in
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for (index, item) in controller.finalItems.enumerated() {

            // WEATHER WIDGET (INLINE MODE)
            if item.bundleIdentifier == "__weather__" {
                let weather = WeatherWidgetView()
                weather.mode = .inline
                weather.translatesAutoresizingMaskIntoConstraints = false

                weather.widthAnchor.constraint(equalToConstant: 48).isActive = true
                weather.heightAnchor.constraint(equalToConstant: 48).isActive = true

                weather.onRequestDisable = {
                    TaskbarSettings.shared.showWeatherWidget = false
                }

                addArrangedSubview(weather)
                continue
            }

            // NORMAL APP ICON (INCLUDING LAUNCHER)
            let iconView = AppIconView(item: item)
            iconView.delegate = self
            iconView.indexInStack = index

            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.widthAnchor.constraint(equalToConstant: 48).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 48).isActive = true

            addArrangedSubview(iconView)
        }
    }

    // MARK: - Running App Hit Test

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

    // MARK: - Launcher Access

    func launcherIconView() -> AppIconView? {
        arrangedSubviews
            .compactMap { $0 as? AppIconView }
            .first { $0.item.bundleIdentifier == controller.lastLauncherBundleID }
    }

    // MARK: - AppIconViewDelegate

    func appIconViewDidBeginDrag(_ view: AppIconView, item: AppItem, index: Int) {

        if item.bundleIdentifier == "__weather__" {
            dragSourceIndex = nil
            return
        }

        if item.bundleIdentifier == controller.lastLauncherBundleID {
            dragSourceIndex = nil
            return
        }

        dragSourceIndex = index
        NotificationCenter.default.post(name: .taskbarDragBegan, object: nil)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        .move
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let location = sender.draggingLocation

        if let sourceIndex = dragSourceIndex {
            let dropIndex = TaskbarDragController.shared.indexForDrop(in: self, at: location)
            controller.movePinnedItem(from: sourceIndex, to: dropIndex)
            dragSourceIndex = dropIndex
        }

        NotificationCenter.default.post(name: .taskbarDragMoved, object: location)
        return .move
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        dragSourceIndex = nil
        NotificationCenter.default.post(name: .taskbarDragEnded, object: nil)
    }

    func appIconViewDidRequestActivate(_ view: AppIconView, item: AppItem) {

        if item.bundleIdentifier == "__weather__" {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.weather") {
                let config = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.openApplication(at: url, configuration: config)
            }
            return
        }

        if let running = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == item.bundleIdentifier
        }) {
            running.activate(options: [.activateAllWindows])
        } else {
            NSWorkspace.shared.open(item.bundleURL)
        }
    }

    func appIconViewDidRequestPin(_ view: AppIconView, item: AppItem) {
        if item.bundleIdentifier == "__weather__" { return }
        controller.pinApp(bundleID: item.bundleIdentifier, path: item.bundleURL.path)
    }

    func appIconViewDidRequestUnpin(_ view: AppIconView, item: AppItem) {
        if item.bundleIdentifier == "__weather__" { return }
        if item.bundleIdentifier == controller.lastLauncherBundleID { return }
        controller.unpinApp(bundleID: item.bundleIdentifier)
    }

    func appIconViewDidRequestQuit(_ view: AppIconView, item: AppItem) {
        if item.bundleIdentifier == "__weather__" { return }
        if let running = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == item.bundleIdentifier
        }) {
            running.terminate()
        }
    }

    func appIconViewIsLauncher(_ view: AppIconView) -> Bool {
        view.item.bundleIdentifier == controller.lastLauncherBundleID
    }

    func moveIcon(from oldIndex: Int, to newIndex: Int) {
        controller.movePinnedItem(from: oldIndex, to: newIndex)
    }
}

