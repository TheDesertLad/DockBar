// File: WeatherWidgetView.swift
// Taskbar weather widget using Open-Meteo
// This was built using Microsoft Copilot

import AppKit
import Combine

final class WeatherWidgetView: NSView {

    enum Mode {
        case left
        case leftOfCenter
    }

    var mode: Mode = .left {
        didSet { needsLayout = true }
    }

    private let iconView = NSImageView()
    private let tempLabel = NSTextField(labelWithString: "--°")

    private var cancellables = Set<AnyCancellable>()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        setupObservers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupObservers()
    }

    private func setupView() {
        wantsLayer = true

        iconView.symbolConfiguration = .init(pointSize: 16, weight: .medium)
        iconView.contentTintColor = .labelColor

        tempLabel.font = .systemFont(ofSize: 13, weight: .medium)
        tempLabel.textColor = .labelColor

        addSubview(iconView)
        addSubview(tempLabel)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        tempLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),

            tempLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 4),
            tempLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            tempLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func setupObservers() {
        let service = WeatherService.shared

        service.$temperatureF
            .receive(on: RunLoop.main)
            .sink { [weak self] temp in
                guard let temp = temp else { return }
                self?.tempLabel.stringValue = "\(temp)°"
            }
            .store(in: &cancellables)

        service.$conditionSymbol
            .receive(on: RunLoop.main)
            .sink { [weak self] symbol in
                guard let symbol = symbol else { return }
                self?.iconView.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            }
            .store(in: &cancellables)
    }

    // MARK: - Click → Open Weather App

    override func mouseDown(with event: NSEvent) {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.weather") {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: config)
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 80, height: 48)
    }
}
