// File: WeatherService.swift
// This was built using Microsoft Copilot

import Foundation
import AppKit
import Combine

final class WeatherService: ObservableObject {

    static let shared = WeatherService()

    @Published var temperatureF: Int?
    @Published var conditionSymbol: String?   // SF Symbol name

    private var timer: AnyCancellable?

    private init() {
        fetchWeather()
        startAutoRefresh()
    }

    // MARK: - Auto Refresh

    private func startAutoRefresh() {
        timer = Timer.publish(every: 900, on: .main, in: .common) // 15 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchWeather()
            }
    }

    // MARK: - Fetch Weather (Open-Meteo)

    func fetchWeather() {
        // West Monroe, LA coordinates
        let latitude = 32.5180
        let longitude = -92.1277

        let urlString =
        "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }

            do {
                let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
                DispatchQueue.main.async {
                    let celsius = decoded.current_weather.temperature
                    let fahrenheit = Int((celsius * 9/5) + 32)
                    self?.temperatureF = fahrenheit
                    self?.conditionSymbol = Self.symbol(for: decoded.current_weather.weathercode)
                }
            } catch {
                print("Weather decode error:", error)
            }
        }.resume()
    }

    // MARK: - Weather Code → SF Symbol

    private static func symbol(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 71, 73, 75: return "cloud.snow.fill"
        case 95: return "cloud.bolt.fill"
        case 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

// MARK: - Open-Meteo Models

nonisolated struct OpenMeteoResponse: Codable {
    let current_weather: CurrentWeather
}

nonisolated struct CurrentWeather: Codable {
    let temperature: Double
    let weathercode: Int
}

