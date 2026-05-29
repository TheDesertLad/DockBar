import AppKit
import SwiftUI
import Combine

class TaskbarWindow: NSWindow {

    private var visualEffectView = NSVisualEffectView()
    private var cancellables = Set<AnyCancellable>()

    private let controller = TaskbarController.shared
    private let taskbarHeight: CGFloat = 48

    init() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        let frame = NSRect(
            x: 0,
            y: 0,
            width: screenFrame.width,
            height: taskbarHeight
        )

        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .statusBar
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        setupVisualEffect()
        setupContentContainer()
        setupObservers()
        setupScreenChangeObserver()
        positionAtBottom()
    }

    private func setupVisualEffect() {
        visualEffectView = NSVisualEffectView(frame: contentView!.bounds)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.material = .hudWindow

        contentView?.addSubview(visualEffectView)
    }

    private func setupContentContainer() {
        let container = controller.contentContainer
        contentView?.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor),
            container.topAnchor.constraint(equalTo: contentView!.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor)
        ])
    }

    private func setupObservers() {
        let settings = TaskbarSettings.shared

        settings.$appearance
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateAppearance()
                }
            }
            .store(in: &cancellables)

        settings.$blurAmount
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateBlur()
                }
            }
            .store(in: &cancellables)

        settings.$launcherEnabled
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.rebuildLayout()
                }
            }
            .store(in: &cancellables)

        settings.$launcherPosition
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.rebuildLayout()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .launcherAppChanged)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.rebuildLayout()
                }
            }
            .store(in: &cancellables)
    }

    private func updateAppearance() {
        let mode = TaskbarSettings.shared.appearance

        switch mode {
        case "Light":
            appearance = NSAppearance(named: .aqua)
        case "Dark":
            appearance = NSAppearance(named: .darkAqua)
        default:
            appearance = nil
        }
    }

    private func updateBlur() {
        let amount = TaskbarSettings.shared.blurAmount
        visualEffectView.alphaValue = CGFloat(amount / 100.0)
    }

    private func rebuildLayout() {
        controller.rebuildLayout()
    }

    func positionAtBottom() {
        guard let screen = NSScreen.main else { return }

        let newFrame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY,
            width: screen.frame.width,
            height: taskbarHeight
        )

        setFrame(newFrame, display: true)
    }

    private func setupScreenChangeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func handleScreenChange(_ notification: Notification) {
        positionAtBottom()
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Taskbar Settings",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let activityItem = NSMenuItem(
            title: "Activity Monitor",
            action: #selector(openActivityMonitor),
            keyEquivalent: ""
        )
        activityItem.image = NSWorkspace.shared.icon(
            forFile: "/System/Applications/Utilities/Activity Monitor.app"
        )
        menu.addItem(activityItem)

        if let view = self.contentView {
            NSMenu.popUpContextMenu(menu, with: event, for: view)
        }
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func openActivityMonitor() {
        NSWorkspace.shared.open(
            URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        )
    }
}
