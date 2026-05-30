// File: WeatherWidgetView.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

final class WeatherWidgetView: NSView {

    enum Mode {
        case inline    // behaves like an app icon in the row
        case anchored  // anchored on the left, with text
    }

    // Callback for disabling weather widget
    var onRequestDisable: (() -> Void)?

    var mode: Mode = .inline {
        didSet { updateLayoutForMode() }
    }

    // MARK: - Layers & Views

    private let highlightLayer = CALayer()      // hover glow (outside border)
    private let borderLayer = CALayer()         // app-icon border/background

    private let emojiLabel = NSTextField(labelWithString: "☀️")
    private let tempLabel = NSTextField(labelWithString: "--°")

    private let badgeView = NSView()            // square badge behind temperature

    private let conditionLabel = NSTextField(labelWithString: "Loading…") // anchored mode only

    private var cancellables = Set<AnyCancellable>()

    // Constraints for the two modes
    private var inlineConstraints: [NSLayoutConstraint] = []
    private var anchoredConstraints: [NSLayoutConstraint] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
        setupView()
        setupObservers()
        updateLayoutForMode()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        setupView()
        setupObservers()
        updateLayoutForMode()
    }

    // MARK: - Setup Layers

    private func setupLayers() {
        wantsLayer = true

        // Highlight layer (behind border, extends outward)
        highlightLayer.cornerRadius = 12
        highlightLayer.backgroundColor = NSColor.clear.cgColor
        highlightLayer.masksToBounds = false
        highlightLayer.zPosition = 0
        layer?.addSublayer(highlightLayer)

        // App border layer (static)
        borderLayer.cornerRadius = 8
        borderLayer.masksToBounds = false   // IMPORTANT: prevents inside glow
        borderLayer.zPosition = 1
        layer?.addSublayer(borderLayer)
    }

    // MARK: - Setup Views

    private func setupView() {
        // Emoji
        emojiLabel.font = .systemFont(ofSize: 18)
        emojiLabel.alignment = .center
        emojiLabel.isEditable = false
        emojiLabel.isBordered = false
        emojiLabel.backgroundColor = .clear
        addSubview(emojiLabel)

        // Badge behind temperature (added BEFORE tempLabel)
        badgeView.wantsLayer = true
        badgeView.layer?.cornerRadius = 4
        badgeView.layer?.zPosition = 0
        addSubview(badgeView)

        // Temperature (added AFTER badgeView)
        tempLabel.font = .systemFont(ofSize: 11, weight: .medium)
        tempLabel.alignment = .center
        tempLabel.isEditable = false
        tempLabel.isBordered = false
        tempLabel.backgroundColor = .clear
        tempLabel.layer?.zPosition = 1
        addSubview(tempLabel)

        // Anchored mode condition text
        conditionLabel.font = .systemFont(ofSize: 11)
        conditionLabel.textColor = .secondaryLabelColor
        conditionLabel.lineBreakMode = .byTruncatingTail
        addSubview(conditionLabel)

        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        tempLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        conditionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Inline (36x36) layout
        inlineConstraints = [
            widthAnchor.constraint(equalToConstant: 36),
            heightAnchor.constraint(equalToConstant: 36),

            emojiLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            emojiLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            badgeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            badgeView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            badgeView.heightAnchor.constraint(equalToConstant: 16),

            tempLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            tempLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),

            conditionLabel.heightAnchor.constraint(equalToConstant: 0)
        ]

        // Anchored layout (unchanged)
        anchoredConstraints = [
            heightAnchor.constraint(equalToConstant: 40),

            emojiLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            emojiLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            tempLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 6),
            tempLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),

            conditionLabel.leadingAnchor.constraint(equalTo: tempLabel.leadingAnchor),
            conditionLabel.topAnchor.constraint(equalTo: tempLabel.bottomAnchor, constant: 2),
            conditionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            conditionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6)
        ]
    }

    // MARK: - Weather Observers

    private func setupObservers() {
        let service = WeatherService.shared

        service.$temperatureF
            .receive(on: RunLoop.main)
            .sink { [weak self] temp in
                guard let self, let temp else { return }
                self.tempLabel.stringValue = "\(temp)°"
                self.updateBadgeWidth()
            }
            .store(in: &cancellables)

        service.$conditionSymbol
            .receive(on: RunLoop.main)
            .sink { [weak self] symbol in
                guard let self else { return }
                let emoji: String
                switch symbol {
                case "sun.max.fill": emoji = "☀️"
                case "cloud.sun.fill": emoji = "⛅️"
                case "cloud.fill": emoji = "☁️"
                case "cloud.fog.fill": emoji = "🌫️"
                case "cloud.drizzle.fill": emoji = "🌦️"
                case "cloud.rain.fill": emoji = "🌧️"
                case "cloud.snow.fill": emoji = "❄️"
                case "cloud.bolt.fill": emoji = "🌩️"
                case "cloud.bolt.rain.fill": emoji = "⛈️"
                default: emoji = "☁️"
                }
                self.emojiLabel.stringValue = emoji
            }
            .store(in: &cancellables)

        service.$conditionSymbol
            .receive(on: RunLoop.main)
            .sink { [weak self] symbol in
                guard let self, let symbol else { return }
                let text: String
                switch symbol {
                case "sun.max.fill": text = "Sunny"
                case "cloud.sun.fill": text = "Partly Cloudy"
                case "cloud.fill": text = "Cloudy"
                case "cloud.fog.fill": text = "Foggy"
                case "cloud.drizzle.fill": text = "Light Rain"
                case "cloud.rain.fill": text = "Rain"
                case "cloud.snow.fill": text = "Snow"
                case "cloud.bolt.fill": text = "Storms"
                case "cloud.bolt.rain.fill": text = "Thunderstorms"
                default: text = "Cloudy"
                }
                self.conditionLabel.stringValue = text
            }
            .store(in: &cancellables)
    }

    // MARK: - Layout Mode Switching

    private func updateLayoutForMode() {
        NSLayoutConstraint.deactivate(inlineConstraints + anchoredConstraints)

        switch mode {
        case .inline:
            conditionLabel.isHidden = true
            badgeView.isHidden = false
            borderLayer.isHidden = false
            highlightLayer.isHidden = false
            updateInlineTheme()
            NSLayoutConstraint.activate(inlineConstraints)

        case .anchored:
            conditionLabel.isHidden = false
            badgeView.isHidden = true

            // No border in anchored mode
            borderLayer.isHidden = true

            // Highlight IS allowed in anchored mode
            highlightLayer.isHidden = false

            NSLayoutConstraint.activate(anchoredConstraints)
        }

        needsLayout = true
        layoutSubtreeIfNeeded()
    }

    // MARK: - Theme Updates

    private func updateInlineTheme() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        // App border (opaque)
        borderLayer.backgroundColor = isDark
            ? NSColor.black.withAlphaComponent(0.30).cgColor
            : NSColor.white.withAlphaComponent(0.20).cgColor

        borderLayer.borderWidth = 1
        borderLayer.borderColor = isDark
            ? NSColor.white.withAlphaComponent(0.20).cgColor
            : NSColor.black.withAlphaComponent(0.20).cgColor

        // Badge behind temperature (fully opaque)
        badgeView.layer?.backgroundColor = isDark
            ? NSColor.black.cgColor
            : NSColor.white.cgColor

        badgeView.layer?.borderWidth = 1
        badgeView.layer?.borderColor = isDark
            ? NSColor.white.withAlphaComponent(0.20).cgColor
            : NSColor.black.withAlphaComponent(0.20).cgColor
    }

    private func updateBadgeWidth() {
        let textWidth = tempLabel.intrinsicContentSize.width + 10
        badgeView.widthAnchor.constraint(equalToConstant: textWidth).isActive = true
    }

    // MARK: - Hover

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.15)
        highlightLayer.backgroundColor =
            NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor
        CATransaction.commit()
    }

    override func mouseExited(with event: NSEvent) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.15)
        highlightLayer.backgroundColor = NSColor.clear.cgColor
        CATransaction.commit()
    }

    // MARK: - Layout

    override func layout() {
        super.layout()

        // Highlight extends outward for proper glow
        highlightLayer.frame = bounds.insetBy(dx: -4, dy: -4)
        highlightLayer.cornerRadius = borderLayer.cornerRadius + 4

        // Border matches view bounds
        borderLayer.frame = bounds

        // Ensure correct z-order
        badgeView.layer?.zPosition = 0
        tempLabel.layer?.zPosition = 1
    }

    // MARK: - Click Handling

    override func mouseDown(with event: NSEvent) {
        if event.type == .leftMouseDown {
            openWeatherApp()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        showDisableMenu()
    }

    private func openWeatherApp() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.weather") {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: config)
        }
    }

    private func showDisableMenu() {
        let menu = NSMenu()

        let disableItem = NSMenuItem(
            title: "Disable Weather Widget",
            action: #selector(disableWeather),
            keyEquivalent: ""
        )
        disableItem.target = self
        menu.addItem(disableItem)

        NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent ?? NSEvent(), for: self)
    }

    @objc private func disableWeather() {
        onRequestDisable?()
    }
}

