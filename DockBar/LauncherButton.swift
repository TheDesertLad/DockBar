import AppKit
import Combine

class LauncherButton: NSButton {

    private var hoverTrackingArea: NSTrackingArea?
    private var isHovering = false
    private var cancellables = Set<AnyCancellable>()

    private let iconSize: CGFloat = 40
    private let hoverCornerRadius: CGFloat = 8

    // MARK: - Init
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 40, height: 40))

        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 0
        layer?.masksToBounds = false

        target = self
        action = #selector(launchApp)

        setupHoverTracking()
        observeLauncherChanges()
        updateIcon()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Hover Tracking
    private func setupHoverTracking() {
        hoverTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(hoverTrackingArea!)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = hoverTrackingArea {
            removeTrackingArea(area)
        }
        setupHoverTracking()
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        animateHover()
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        animateHover()
    }

    private func animateHover() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            if isHovering {
                self.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.18).cgColor
                self.layer?.cornerRadius = self.hoverCornerRadius
            } else {
                self.layer?.backgroundColor = NSColor.clear.cgColor
                self.layer?.cornerRadius = 0
            }
        }
    }

    // MARK: - Observe Launcher Changes
    private func observeLauncherChanges() {
        TaskbarSettings.shared.$launcherAppPath
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)
    }

    // MARK: - Icon Loading
    func updateIcon() {
        let path = TaskbarSettings.shared.launcherAppPath

        guard FileManager.default.fileExists(atPath: path) else {
            self.image = nil
            return
        }

        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: iconSize, height: iconSize)

        self.image = icon
        self.imageScaling = .scaleProportionallyUpOrDown
    }

    // MARK: - Launch App
    @objc private func launchApp() {
        let path = TaskbarSettings.shared.launcherAppPath
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }
}
