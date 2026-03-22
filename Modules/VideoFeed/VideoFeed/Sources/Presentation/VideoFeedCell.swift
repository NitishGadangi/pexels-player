import UIKit
import UIComponents
import SharedModelsInterface

protocol VideoFeedCellDelegate: AnyObject {
    func cellDidTapPlayPause(_ cell: VideoFeedCell)
    func cellDidTapMute(_ cell: VideoFeedCell)
    func cellDidTapSave(_ cell: VideoFeedCell)
    func cellDidTapShare(_ cell: VideoFeedCell)
    func cellDidTapQuality(_ cell: VideoFeedCell)
}

final class VideoFeedCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoFeedCell"

    weak var delegate: VideoFeedCellDelegate?

    let playerContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    let previewImageView: RemoteImageView = {
        let iv = RemoteImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let playPauseIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.fill"))
        iv.tintColor = .white.withAlphaComponent(0.8)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowOpacity = 0.8
        label.layer.shadowRadius = 2
        return label
    }()

    let progressBar: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progressTintColor = .white
        pv.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()

    private let muteButton = VideoFeedCell.makeButton(systemName: "speaker.wave.2.fill")
    private let saveButton = VideoFeedCell.makeButton(systemName: "bookmark")
    private let shareButton = VideoFeedCell.makeButton(systemName: "square.and.arrow.up")
    let qualityButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("HD", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        btn.layer.cornerRadius = 4
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var buttonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [muteButton, saveButton, shareButton, qualityButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        previewImageView.cancelLoad()
        previewImageView.image = nil
        previewImageView.isHidden = false
        loadingIndicator.stopAnimating()
        playPauseIcon.isHidden = true
        progressBar.progress = 0
    }

    private func setupViews() {
        contentView.backgroundColor = .black

        contentView.addSubview(playerContainerView)
        contentView.addSubview(previewImageView)
        contentView.addSubview(loadingIndicator)
        contentView.addSubview(playPauseIcon)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(progressBar)
        contentView.addSubview(buttonStack)

        playerContainerView.pinToEdges(of: contentView)
        previewImageView.pinToEdges(of: contentView)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            playPauseIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playPauseIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playPauseIcon.widthAnchor.constraint(equalToConstant: 50),
            playPauseIcon.heightAnchor.constraint(equalToConstant: 50),

            usernameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            usernameLabel.bottomAnchor.constraint(equalTo: progressBar.topAnchor, constant: -20),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: buttonStack.leadingAnchor, constant: -16),

            progressBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            progressBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -34),
            progressBar.heightAnchor.constraint(equalToConstant: 2),

            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            buttonStack.bottomAnchor.constraint(equalTo: usernameLabel.bottomAnchor),

            muteButton.widthAnchor.constraint(equalToConstant: 40),
            muteButton.heightAnchor.constraint(equalToConstant: 40),
            saveButton.widthAnchor.constraint(equalToConstant: 40),
            saveButton.heightAnchor.constraint(equalToConstant: 40),
            shareButton.widthAnchor.constraint(equalToConstant: 40),
            shareButton.heightAnchor.constraint(equalToConstant: 40),
            qualityButton.widthAnchor.constraint(equalToConstant: 40),
            qualityButton.heightAnchor.constraint(equalToConstant: 28),
        ])

        muteButton.addTarget(self, action: #selector(didTapMute), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)
        qualityButton.addTarget(self, action: #selector(didTapQuality), for: .touchUpInside)
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCell))
        contentView.addGestureRecognizer(tap)
    }

    func configure(with video: Video, quality: VideoQuality) {
        previewImageView.loadImage(from: video.image)
        usernameLabel.text = "@\(video.user.name)"
        qualityButton.setTitle(quality.displayName, for: .normal)
    }

    func showBuffering(_ show: Bool) {
        if show {
            loadingIndicator.startAnimating()
            previewImageView.isHidden = false
        } else {
            loadingIndicator.stopAnimating()
            previewImageView.isHidden = true
        }
    }

    func showPaused(_ paused: Bool) {
        playPauseIcon.image = UIImage(systemName: paused ? "play.fill" : "pause.fill")
        if paused {
            playPauseIcon.isHidden = false
            playPauseIcon.alpha = 1.0
        } else {
            UIView.animate(withDuration: 0.3) {
                self.playPauseIcon.alpha = 0
            } completion: { _ in
                self.playPauseIcon.isHidden = true
            }
        }
    }

    func updateMuteButton(isMuted: Bool) {
        let imageName = isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        muteButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    private static func makeButton(systemName: String) -> UIButton {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        btn.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowOpacity = 0.6
        btn.layer.shadowRadius = 2
        return btn
    }

    @objc private func didTapCell() { delegate?.cellDidTapPlayPause(self) }
    @objc private func didTapMute() { delegate?.cellDidTapMute(self) }
    @objc private func didTapSave() { delegate?.cellDidTapSave(self) }
    @objc private func didTapShare() { delegate?.cellDidTapShare(self) }
    @objc private func didTapQuality() { delegate?.cellDidTapQuality(self) }
}
