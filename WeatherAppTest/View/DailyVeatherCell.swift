import UIKit

final class DailyWeatherCell: UITableViewCell {
    private let dayLabel = UILabel()
    private let iconView = UIImageView()
    private let tempLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        let stack = UIStackView(arrangedSubviews: [dayLabel, iconView, tempLabel])
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 16
        contentView.backgroundColor = .secondarySystemBackground

        dayLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        dayLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        tempLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        tempLabel.textAlignment = .right

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            dayLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5)
        ])
    }

    func configure(with day: ForecastDay) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: day.date) {
            dateFormatter.dateFormat = "EEEE"
            dayLabel.text = dateFormatter.string(from: date)
        } else {
            dayLabel.text = day.date
        }

        tempLabel.text = "\(Int(day.day.averageTemperatureC))°"

        if let iconUrl = URL(string: "https:\(day.day.condition.icon)") {
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
