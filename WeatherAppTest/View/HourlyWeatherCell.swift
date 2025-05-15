import UIKit

final class HourlyWeatherCell: UICollectionViewCell {
    private let timeLabel = UILabel()
    private let iconView = UIImageView()
    private let tempLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        let stack = UIStackView(arrangedSubviews: [timeLabel, iconView, tempLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4

        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        timeLabel.textColor = .secondaryLabel

        iconView.contentMode = .scaleAspectFit

        tempLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    func configure(with hour: HourWeather) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let date = dateFormatter.date(from: hour.time) {
            dateFormatter.dateFormat = "ha"
            timeLabel.text = dateFormatter.string(from: date)
        } else {
            timeLabel.text = hour.time
        }

        tempLabel.text = "\(Int(hour.temperatureC))°"

        if let iconUrl = URL(string: "https:\(hour.condition.icon)") {
            URLSession.shared.dataTask(with: iconUrl) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.iconView.image = image
                    }
                }
            }.resume()
        }
    }
}
