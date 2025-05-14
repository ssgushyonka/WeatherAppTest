import Foundation

struct WeatherResponse: Codable {
    let location: Location
    let current: CurrentWeather
    let forecast: Forecast
}

struct Location: Codable {
    let name: String
    let lat: Double
    let lon: Double
}

struct CurrentWeather: Codable {
    let temperatureC: Double
    let condition: Condition
    let windKph: Double
    let humidity: Int
    let pressureMb: Double
    let visibilityKm: Double

    enum CodingKeys: String, CodingKey {
        case temperatureC = "temp_c"
        case condition
        case windKph = "wind_kph"
        case humidity
        case pressureMb = "pressure_mb"
        case visibilityKm = "vis_km"
    }
}

struct Forecast: Codable {
    let forecastDay: [ForecastDay]

    enum CodingKeys: String, CodingKey {
        case forecastDay = "forecastday"
    }
}

struct ForecastDay: Codable {
    let date: String
    let hours: [HourWeather]
    let day: DayWeather

    enum CodingKeys: String, CodingKey {
        case date
        case hours = "hour"
        case day
    }
}

struct HourWeather: Codable {
    let time: String
    let temperatureC: Double
    let condition: Condition

    enum CodingKeys: String, CodingKey {
        case time
        case temperatureC = "temp_c"
        case condition
    }
}

struct DayWeather: Codable {
    let averageTemperatureC: Double
    let condition: Condition

    enum CodingKeys: String, CodingKey {
        case averageTemperatureC = "avgtemp_c"
        case condition
    }
}

struct Condition: Codable {
    let text: String
    let icon: String
}
