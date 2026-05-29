// File: TaskbarDragController.swift
// This was built using Microsoft Copilot

import AppKit

final class TaskbarDragController {

    static let shared = TaskbarDragController()

    private init() {}

    func indexForDrop(in stackView: NSStackView, at point: NSPoint) -> Int {
        let localPoint = stackView.convert(point, from: stackView.window?.contentView)
        let views = stackView.arrangedSubviews

        if views.isEmpty { return 0 }

        for (index, view) in views.enumerated() {
            let frame = view.frame
            if localPoint.x < frame.midX {
                return index
            }
        }
        return views.count
    }
}
