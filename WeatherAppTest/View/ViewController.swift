import UIKit
import CoreLocation

final class ViewController: UIViewController {
    private let viewModel = WeatherViewModel()
    private let locationManager = LocationManager()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var forecastDays: [ForecastDay] = []
    private var hourlyForecast: [HourWeather] = []

    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorView = UIView()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    private let currentWeatherView = UIView()
    private let locationLabel = UILabel()
    private let temperatureLabel = UILabel()
    private let conditionLabel = UILabel()
    private let weatherIcon = UIImageView()
    private let feelsLikeLabel = UILabel()
    private let detailsStack = UIStackView()
    private let dailyTableView = UITableView()

    private let hourlyCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 100)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        bindViewModel()
        locationManager.delegate = self
        locationManager.checkAuthorizationStatus()
    }

    private func fallbackToMoscow() {
        viewModel.fetchWeather(for: "Moscow")
    }

    private func setupViews() {
        view.backgroundColor = .white

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)

        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.backgroundColor = .systemRed.withAlphaComponent(0.1)
        errorView.layer.cornerRadius = 10
        errorView.isHidden = true

        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center

        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.setTitle("Try Again", for: .normal)
        retryButton.setTitleColor(.systemBlue, for: .normal)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        errorView.addSubview(errorLabel)
        errorView.addSubview(retryButton)
        view.addSubview(errorView)

        detailsStack.axis = .horizontal
        detailsStack.distribution = .fillEqually
        detailsStack.spacing = 8
        detailsStack.alignment = .fill
        detailsStack.translatesAutoresizingMaskIntoConstraints = false

        currentWeatherView.translatesAutoresizingMaskIntoConstraints = false
        currentWeatherView.layer.cornerRadius = 12
        currentWeatherView.backgroundColor = .secondarySystemBackground

        locationLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        locationLabel.textAlignment = .center

        temperatureLabel.font = UIFont.systemFont(ofSize: 60, weight: .thin)

        conditionLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        conditionLabel.textAlignment = .center

        weatherIcon.contentMode = .scaleAspectFit

        feelsLikeLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        feelsLikeLabel.textColor = .secondaryLabel

        detailsStack.axis = .horizontal
        detailsStack.distribution = .fillEqually
        detailsStack.spacing = 8
        setupSubViews()
    }

    private func setupSubViews() {
        let currentWeatherStack = UIStackView(
            arrangedSubviews: [
                locationLabel,
                temperatureLabel,
                conditionLabel,
                weatherIcon,
                feelsLikeLabel]
        )
        currentWeatherStack.axis = .vertical
        currentWeatherStack.alignment = .center
        currentWeatherStack.spacing = 8

        currentWeatherView.addSubview(currentWeatherStack)
        currentWeatherView.addSubview(detailsStack)
        contentView.addSubview(currentWeatherView)

        hourlyCollectionView.translatesAutoresizingMaskIntoConstraints = false
        hourlyCollectionView.register(HourlyWeatherCell.self, forCellWithReuseIdentifier: "HourlyCell")
        hourlyCollectionView.dataSource = self
        contentView.addSubview(hourlyCollectionView)

        dailyTableView.translatesAutoresizingMaskIntoConstraints = false
        dailyTableView.register(DailyWeatherCell.self, forCellReuseIdentifier: "DailyCell")
        dailyTableView.dataSource = self
        dailyTableView.delegate = self
        dailyTableView.rowHeight = 60
        dailyTableView.isScrollEnabled = false
        dailyTableView.layer.cornerRadius = 12
        dailyTableView.backgroundColor = .secondarySystemBackground
        contentView.addSubview(dailyTableView)
    }

    // MARK: - Set up constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),

            errorLabel.topAnchor.constraint(equalTo: errorView.topAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -16),

            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 12),
            retryButton.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            retryButton.bottomAnchor.constraint(equalTo: errorView.bottomAnchor, constant: -16),

            currentWeatherView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            currentWeatherView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            currentWeatherView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            hourlyCollectionView.topAnchor.constraint(equalTo: currentWeatherView.bottomAnchor, constant: 24),
            hourlyCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hourlyCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            hourlyCollectionView.heightAnchor.constraint(equalToConstant: 120),

            dailyTableView.topAnchor.constraint(equalTo: hourlyCollectionView.bottomAnchor, constant: 24),
            dailyTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dailyTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dailyTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])

        guard let currentWeatherStack = currentWeatherView.subviews.first as? UIStackView else {
            fatalError("Expected a UIStackView")
        }
        currentWeatherStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            currentWeatherStack.topAnchor.constraint(equalTo: currentWeatherView.topAnchor, constant: 20),
            currentWeatherStack.leadingAnchor.constraint(equalTo: currentWeatherView.leadingAnchor, constant: 16),
            currentWeatherStack.trailingAnchor.constraint(equalTo: currentWeatherView.trailingAnchor, constant: -16),

            weatherIcon.widthAnchor.constraint(equalToConstant: 60),
            weatherIcon.heightAnchor.constraint(equalToConstant: 60),

            detailsStack.topAnchor.constraint(equalTo: currentWeatherStack.bottomAnchor, constant: 16),
            detailsStack.leadingAnchor.constraint(equalTo: currentWeatherView.leadingAnchor, constant: 8),
            detailsStack.trailingAnchor.constraint(equalTo: currentWeatherView.trailingAnchor, constant: -8),
            detailsStack.bottomAnchor.constraint(equalTo: currentWeatherView.bottomAnchor, constant: -16)
        ])
    }

    private func bindViewModel() {
        viewModel.onLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                isLoading ? self?.loadingIndicator.startAnimating() : self?.loadingIndicator.stopAnimating()
            }
        }

        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.errorLabel.text = message
                self?.errorView.isHidden = false
            }
        }

        viewModel.onUpdate = { [weak self] weather in
            print("Received forecast days:", weather?.forecast.forecastDay.count ?? 0)
            DispatchQueue.main.async {
                guard let self = self, let weather = weather else { return }
                self.errorView.isHidden = true
                self.forecastDays = weather.forecast.forecastDay
                self.hourlyForecast = weather.forecast.forecastDay.first?.hours ?? []
                self.updateUI(with: weather)
                self.dailyTableView.reloadData()
                self.hourlyCollectionView.reloadData()

                let tableHeight = self.dailyTableView.rowHeight * CGFloat(self.forecastDays.count)
                self.dailyTableView.heightAnchor.constraint(equalToConstant: tableHeight).isActive = true

                self.view.layoutIfNeeded()
            }
        }
    }

    private func updateUI(with weather: WeatherResponse) {
        locationLabel.text = "\(weather.location.name)"
        temperatureLabel.text = "\(Int(weather.current.temperatureC))°"
        conditionLabel.text = weather.current.condition.text
        feelsLikeLabel.text = "Feels like \(Int(weather.current.temperatureC))°"

        if let iconUrl = URL(string: "https:\(weather.current.condition.icon)") {
            URLSession.shared.dataTask(with: iconUrl) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.weatherIcon.image = image
                    }
                }
            }.resume()
        }

        detailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let details = [
            ("Wind", "\(Int(weather.current.windKph)) km/h"),
            ("Humidity", "\(weather.current.humidity)%"),
            ("Pressure", "\(Int(weather.current.pressureMb)) mb"),
            ("Visibility", "\(weather.current.visibilityKm) km")
        ]

        for (title, value) in details {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.textColor = .gray
            titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            titleLabel.textAlignment = .center

            let valueLabel = UILabel()
            valueLabel.text = value
            valueLabel.font = UIFont.systemFont(ofSize: 16)
            valueLabel.textAlignment = .center

            let verticalStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
            verticalStack.axis = .vertical
            verticalStack.alignment = .center
            verticalStack.spacing = 2

            detailsStack.addArrangedSubview(verticalStack)
        }
    }

    @objc private func retryTapped() {
        errorView.isHidden = true
        locationManager.checkAuthorizationStatus()
    }
}

// MARK: - CollectionView DataSource
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hourlyForecast.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HourlyCell", for: indexPath)
                as? HourlyWeatherCell else {
            fatalError("Unable to dequeue HourlyWeatherCell")
        }
        cell.configure(with: hourlyForecast[indexPath.item])
        return cell
    }
}

// MARK: - TableView DataSource & Delegate
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forecastDays.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DailyCell", for: indexPath)
                as? DailyWeatherCell else {
            fatalError("Unable to dequeue DailyWeatherCell")
        }
        cell.configure(with: forecastDays[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "7-Day Forecast"
    }
}

// MARK: - Location Manager Delegate
extension ViewController: LocationManagerDelegate {
    func didUpdateLocation(_ location: CLLocation) {
        let coords = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        viewModel.fetchWeather(for: coords)
    }

    func didFailWithError(_ error: Error) {
        print("Location error: \(error.localizedDescription)")
        fallbackToMoscow()
    }

    func didChangeAuthorization(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            fallbackToMoscow()
        default:
            break
        }
    }
}
