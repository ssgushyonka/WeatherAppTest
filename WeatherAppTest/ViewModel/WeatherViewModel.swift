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

    func fetchWeather(for location: String) {
            onLoading?(true)
            let urlString =
        "https://api.weatherapi.com/v1/forecast.json?key=\(apiKey)&q=\(location)&days=7&aqi=no&alerts=no"

            guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: encodedURLString) else {
                onError?("Invalid location")
                return
            }

            URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                DispatchQueue.main.async {
                    self?.onLoading?(false)

                    if let error = error {
                        self?.onError?("Ошибка сети: \(error.localizedDescription)")
                        return
                    }

                    guard let data = data else {
                        self?.onError?("Нет данных")
                        return
                    }

                    do {
                        let weather = try JSONDecoder().decode(WeatherResponse.self, from: data)
                        self?.onUpdate?(weather)
                    } catch {
                        self?.onError?("Ошибка обработки данных")
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
