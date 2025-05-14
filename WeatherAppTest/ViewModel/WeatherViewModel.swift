import Foundation
import CoreLocation

final class WeatherViewModel: NSObject {
    private let locationManager = CLLocationManager()
    private let apiKey = "fa8b3df74d4042b9aa7135114252304"
    private let defaultCity = "Moscow"

    var onUpdate: ((WeatherResponse?) -> Void)?
    var onError: ((String) -> Void)?
    var onLoading: ((Bool) -> Void)?

    func requestLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    private func fetchWeather(for query: String) {
        onLoading?(true)
        let urlString = "https://api.weatherapi.com/v1/forecast.json?key=\(apiKey)&q=\(query)&days=7&aqi=no&alerts=no"

        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.onLoading?(false)
            }

            if let error = error {
                DispatchQueue.main.async {
                    self?.onError?("Network error: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self?.onError?("No data returned")
                }
                return
            }

            do {
                let weather = try JSONDecoder().decode(WeatherResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.onUpdate?(weather)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.onError?("Failed to decode response")
                }
            }
        }.resume()
    }
}

extension WeatherViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let query = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
            fetchWeather(for: query)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        fetchWeather(for: defaultCity)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            fetchWeather(for: defaultCity)
        }
    }
}
