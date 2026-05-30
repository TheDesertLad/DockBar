// File: WeatherModel.swift
// This was built using Microsoft Copilot

import Foundation
import AppKit

struct WeatherModel {
    let temperature: String
    let condition: String
    let highLow: String
    let symbolName: String

    var icon: NSImage? {
        if #available(macOS 13.0, *) {
            return NSImage(systemSymbolName: symbolName, accessibilityDescription: condition)
        } else {
            return nil
        }
    }
}
