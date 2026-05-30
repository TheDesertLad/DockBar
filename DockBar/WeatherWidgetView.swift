// File: WeatherWidgetView.swift
// This was built using Microsoft Copilot

import AppKit
import Combine

final class WeatherWidgetView: NSView {

    enum Mode {
        case left
        case leftOfCenter
    }

    private let iconView = NSImageView()
    private let tempLabel = NSTextField(labelWithString: "--")
    private let conditionLabel = NSTextField(labelWithString: "")
    private let hiLoLabel = NSTextField(labelWithString: "")

    private var cancellables = Set<AnyCancellable>()
    var mode: Mode = .left {
        didSet { updateLayoutForMode() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
        bindWeather()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        bindWeather()
    }

    private func setupViews() {
        wantsLayer = true

        iconView.imageScaling = .scaleProportionallyUpOrDown

        [tempLabel, conditionLabel, hiLoLabel].forEach {
            $0.font = NSFont.systemFont(ofSize: 11, weight: .medium)
            $0.textColor = .labelColor
            $0.alignment = .left
        }

        tempLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        conditionLabel.font = NSFont.systemFont(ofSize: 10)
        hiLoLabel.font = NSFont.systemFont(ofSize: 9)

        let textStack = NSStackView(views: [tempLabel, conditionLabel, hiLoLabel])
        textStack.orientation = .vertical
        textStack.spacing = 0

        let hStack = NSStackView(views: [iconView, textStack])
        hStack.orientation = .horizontal
        hStack.spacing = 4
        hStack.alignment = .centerY

        addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            hStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        updateLayoutForMode()
    }

    private func updateLayoutForMode() {
        switch mode {
        case .left:
            widthAnchor.constraint(equalToConstant: 80).isActive = true
        case .leftOfCenter:
            widthAnchor.constraint(equalToConstant: 140).isActive = true
        }
        heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    private func bindWeather() {
        if #available(macOS 13.0, *) {
            TaskbarWeatherService.shared.$currentWeather
                .receive(on: RunLoop.main)
                .sink { [weak self] model in
                    guard let self = self, let model = model else { return }
                    self.tempLabel.stringValue = model.temperature
                    self.conditionLabel.stringValue = model.condition
                    self.hiLoLabel.stringValue = model.highLow
                    self.iconView.image = model.icon
                }
                .store(in: &cancellables)
        }
    }
}
