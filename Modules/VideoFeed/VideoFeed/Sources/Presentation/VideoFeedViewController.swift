import UIKit
import Combine
import UIComponents
import SharedModelsInterface

final class VideoFeedViewController: UIViewController {
    private let viewModel: VideoFeedViewModel
    private var cancellables = Set<AnyCancellable>()
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
        viewModel.actionHandler.send(.viewDidLoad)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasScrolledToStart, viewModel.numberOfItems > 0 {
            handleReloadData()
        }
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

    // MARK: - State Binding

    private func bindState() {
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)

        viewModel.reloadData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleReloadData() }
            .store(in: &cancellables)

        viewModel.isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMuted in
                self?.visibleCell()?.updateMuteButton(isMuted: isMuted)
            }
            .store(in: &cancellables)

        viewModel.playbackProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.visibleCell()?.progressBar.progress = Float(progress)
            }
            .store(in: &cancellables)

        viewModel.autoAdvance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] nextIndex in
                self?.handleAutoAdvance(to: nextIndex)
            }
            .store(in: &cancellables)

        viewModel.prepareVideo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] video, index in
                self?.handlePrepareVideo(video, at: index)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: VideoFeedViewModel.State) {
        switch state {
        case .idle:
            break
        case .buffering(let index):
            handleBuffering(at: index)
        case .playing(let index):
            handlePlaying(at: index)
        case .paused:
            handlePaused()
        case .error(let message, _):
            handleError(message)
        }
    }

    // MARK: - State Handlers

    private func handleReloadData() {
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        if !hasScrolledToStart {
            scrollToStart()
        }
    }

    private func handleBuffering(at index: Int) {
        let cell = cellForVideo(at: index)
        cell?.showBuffering(true)
        cell?.showPaused(false)
    }

    private func handlePlaying(at index: Int) {
        let cell = cellForVideo(at: index)
        cell?.showBuffering(false)
        cell?.showPaused(false)
    }

    private func handlePaused() {
        visibleCell()?.showPaused(true)
    }

    private func handleError(_ message: String) {
        let alert = UIAlertController(title: "Playback Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.viewModel.actionHandler.send(.didDismissError)
        })
        present(alert, animated: true)
    }

    private func handleAutoAdvance(to nextIndex: Int) {
        guard nextIndex < viewModel.numberOfItems else { return }
        let indexPath = IndexPath(item: nextIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.viewModel.actionHandler.send(.didScrollTo(index: nextIndex))
        }
    }

    private func handlePrepareVideo(_ video: Video, at index: Int) {
        let cell = cellForVideo(at: index)
        cell?.showBuffering(true)
        guard let container = cell?.playerContainerView else { return }
        viewModel.playerManager.prepareAndPlay(video: video, at: index, in: container)
    }

    // MARK: - Helpers

    private func scrollToStart() {
        guard !hasScrolledToStart, viewModel.startIndex < viewModel.numberOfItems else { return }
        hasScrolledToStart = true
        let indexPath = IndexPath(item: viewModel.startIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.viewModel.actionHandler.send(.didScrollTo(index: self.viewModel.startIndex))
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

    @objc private func didTapBack() {
        viewModel.actionHandler.send(.backTapped)
    }
}

// MARK: - UICollectionViewDataSource

extension VideoFeedViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoFeedCell.reuseIdentifier,
            for: indexPath
        ) as? VideoFeedCell,
              let video = viewModel.video(at: indexPath.item) else {
            return UICollectionViewCell()
        }
        cell.configure(with: video, quality: viewModel.playerManager.qualityService.currentQuality)
        cell.delegate = self
        cell.updateMuteButton(isMuted: viewModel.isMuted.value)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension VideoFeedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        view.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.y / scrollView.bounds.height)
        guard index != viewModel.currentIndex, index >= 0, index < viewModel.numberOfItems else { return }
        viewModel.actionHandler.send(.didScrollTo(index: index))
    }
}

// MARK: - VideoFeedCellDelegate

extension VideoFeedViewController: VideoFeedCellDelegate {
    func cellDidTapPlayPause(_ cell: VideoFeedCell) {
        viewModel.actionHandler.send(.togglePlayPause)
    }

    func cellDidTapMute(_ cell: VideoFeedCell) {
        viewModel.actionHandler.send(.toggleMute)
    }

    func cellDidTapSave(_ cell: VideoFeedCell) {
        //TODO: Calls viewModel.actionHandler when needed
    }

    func cellDidTapShare(_ cell: VideoFeedCell) {
        //TODO: Calls viewModel.actionHandler when needed
    }

    func cellDidTapQuality(_ cell: VideoFeedCell) {
        viewModel.actionHandler.send(.tapQuality)
    }
}
