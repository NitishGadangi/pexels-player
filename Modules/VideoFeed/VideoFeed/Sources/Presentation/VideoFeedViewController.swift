import UIKit
import Combine
import UIComponents
import SharedModelsInterface

final class VideoFeedViewController: UIViewController {
    private let viewModel: VideoFeedViewModel
    private var cancellables = Set<AnyCancellable>()
    private var videos: [Video] = []
    private var hasScrolledToStart = false

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(VideoFeedCell.self, forCellWithReuseIdentifier: VideoFeedCell.reuseIdentifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()

    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowOpacity = 0.6
        btn.layer.shadowRadius = 2
        return btn
    }()

    init(viewModel: VideoFeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindState()
        bindVideos()
        viewModel.action.send(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.playerManager.pauseAll()
    }

    override var prefersStatusBarHidden: Bool { true }

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(collectionView)
        collectionView.pinToEdges(of: view)

        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func bindVideos() {
        viewModel.paginationManager.videosPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] videos in
                guard let self else { return }
                let oldCount = self.videos.count
                self.videos = videos
                if oldCount == 0 {
                    self.collectionView.reloadData()
                    self.scrollToStart()
                } else if videos.count > oldCount {
                    let indexPaths = (oldCount..<videos.count).map { IndexPath(item: $0, section: 0) }
                    self.collectionView.insertItems(at: indexPaths)
                }
            }
            .store(in: &cancellables)
    }

    private func bindState() {
        viewModel.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)

        viewModel.isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMuted in
                guard let self else { return }
                let cell = self.visibleCell()
                cell?.updateMuteButton(isMuted: isMuted)
            }
            .store(in: &cancellables)

        viewModel.playbackProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self else { return }
                let cell = self.visibleCell()
                cell?.progressBar.progress = Float(progress)
            }
            .store(in: &cancellables)

        viewModel.autoAdvance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] nextIndex in
                guard let self, nextIndex < self.videos.count else { return }
                let indexPath = IndexPath(item: nextIndex, section: 0)
                self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.viewModel.action.send(.didScrollTo(index: nextIndex))
                }
            }
            .store(in: &cancellables)

        viewModel.prepareVideo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] video, index in
                guard let self else { return }
                let cell = self.cellForVideo(at: index)
                cell?.showBuffering(true)
                guard let container = cell?.playerContainerView else { return }
                self.viewModel.playerManager.prepareAndPlay(video: video, at: index, in: container)
            }
            .store(in: &cancellables)

        viewModel.showQualitySheet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] files, currentQuality in
                self?.presentQualitySheet(files: files, currentQuality: currentQuality)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: VideoFeedViewModel.State) {
        switch state {
        case .idle:
            break
        case .buffering(let index):
            let cell = cellForVideo(at: index)
            cell?.showBuffering(true)
            cell?.showPaused(false)
        case .playing(let index):
            let cell = cellForVideo(at: index)
            cell?.showBuffering(false)
            cell?.showPaused(false)
        case .paused:
            let cell = visibleCell()
            cell?.showPaused(true)
        case .error(let message, _):
            showErrorAlert(message: message)
        }
    }

    private func scrollToStart() {
        guard !hasScrolledToStart, viewModel.startIndex < videos.count else { return }
        hasScrolledToStart = true
        let indexPath = IndexPath(item: viewModel.startIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.viewModel.action.send(.didScrollTo(index: self.viewModel.startIndex))
        }
    }

    private func visibleCell() -> VideoFeedCell? {
        let center = CGPoint(x: collectionView.bounds.midX, y: collectionView.bounds.midY)
        guard let indexPath = collectionView.indexPathForItem(at: center) else { return nil }
        return collectionView.cellForItem(at: indexPath) as? VideoFeedCell
    }

    private func cellForVideo(at index: Int) -> VideoFeedCell? {
        let indexPath = IndexPath(item: index, section: 0)
        return collectionView.cellForItem(at: indexPath) as? VideoFeedCell
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Playback Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.viewModel.action.send(.didDismissError)
        })
        present(alert, animated: true)
    }

    private func presentQualitySheet(files: [VideoFile], currentQuality: VideoQuality) {
        let vc = QualityBottomSheetViewController(
            videoFiles: files,
            currentQuality: currentQuality
        ) { [weak self] selectedQuality in
            guard let self else { return }
            self.viewModel.action.send(.selectQuality(selectedQuality))
            let cell = self.visibleCell()
            cell?.qualityButton.setTitle(selectedQuality.displayName, for: .normal)
            if self.viewModel.currentIndex < self.videos.count {
                self.viewModel.playerManager.reloadCurrentVideo(
                    video: self.videos[self.viewModel.currentIndex],
                    at: self.viewModel.currentIndex,
                    in: cell?.playerContainerView ?? UIView()
                )
            }
        }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    @objc private func didTapBack() {
        viewModel.action.send(.backTapped)
    }
}

extension VideoFeedViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoFeedCell.reuseIdentifier,
            for: indexPath
        ) as? VideoFeedCell else {
            return UICollectionViewCell()
        }
        let video = videos[indexPath.item]
        cell.configure(with: video, quality: viewModel.playerManager.qualityService.currentQuality)
        cell.delegate = self
        cell.updateMuteButton(isMuted: viewModel.isMuted.value)
        return cell
    }
}

extension VideoFeedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        view.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.y / scrollView.bounds.height)
        guard index != viewModel.currentIndex, index >= 0, index < videos.count else { return }
        viewModel.action.send(.didScrollTo(index: index))
    }
}

extension VideoFeedViewController: VideoFeedCellDelegate {
    func cellDidTapPlayPause(_ cell: VideoFeedCell) {
        viewModel.action.send(.togglePlayPause)
    }

    func cellDidTapMute(_ cell: VideoFeedCell) {
        viewModel.action.send(.toggleMute)
    }

    func cellDidTapSave(_ cell: VideoFeedCell) {}
    func cellDidTapShare(_ cell: VideoFeedCell) {}

    func cellDidTapQuality(_ cell: VideoFeedCell) {
        viewModel.action.send(.tapQuality)
    }
}
