import UIKit
import UIComponents
import SharedModelsInterface

final class VideoThumbnailCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoThumbnailCell"

    private let thumbnailImageView = RemoteImageView()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.layer.cornerRadius = 3
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.5).cgColor]
        layer.locations = [0.6, 1.0]
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.cancelLoad()
        thumbnailImageView.image = nil
    }

    private func setupViews() {
        contentView.backgroundColor = AppTheme.cellBackground
        contentView.clipsToBounds = true

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailImageView)
        thumbnailImageView.pinToEdges(of: contentView)

        contentView.layer.addSublayer(gradientLayer)
        contentView.addSubview(durationLabel)

        NSLayoutConstraint.activate([
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 32),
            durationLabel.heightAnchor.constraint(equalToConstant: 18),
        ])
    }

    func configure(with video: Video) {
        thumbnailImageView.loadImage(from: video.image)
        durationLabel.text = " \(formatDuration(video.duration)) "
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
