// File: WeatherService.swift
// This was built using Microsoft Copilot

import Foundation
import Combine
import CoreLocation
import WeatherKit

@available(macOS 13.0, *)
final class TaskbarWeatherService: NSObject, ObservableObject {

    static let shared = TaskbarWeatherService()

    @Published var currentWeather: WeatherModel?

    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func start() {
        requestLocationIfNeeded()
    }

    private func requestLocationIfNeeded() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            break
        }
    }

    private func fetchWeather(for location: CLLocation) {
        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                let temp = weather.currentWeather.temperature
                let hi = weather.dailyForecast.forecast.first?.highTemperature
                let lo = weather.dailyForecast.forecast.first?.lowTemperature

                let formatter = MeasurementFormatter()
                formatter.unitOptions = .temperatureWithoutUnit
                formatter.numberFormatter.maximumFractionDigits = 0

                let tempString = formatter.string(from: temp)
                let hiString = hi.map { formatter.string(from: $0) } ?? ""
                let loString = lo.map { formatter.string(from: $0) } ?? ""

                let highLow = (!hiString.isEmpty && !loString.isEmpty)
                    ? "H \(hiString)  L \(loString)"
                    : ""

                let model = WeatherModel(
                    temperature: tempString,
                    condition: weather.currentWeather.condition.description,
                    highLow: highLow,
                    symbolName: weather.currentWeather.symbolName
                )

                DispatchQueue.main.async {
                    self.currentWeather = model
                }
            } catch {
                // Ignore failures
            }
        }
    }
}

@available(macOS 13.0, *)
extension TaskbarWeatherService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocationIfNeeded()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        fetchWeather(for: loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
