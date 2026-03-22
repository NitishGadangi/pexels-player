import UIKit
import Combine
import UIComponents
import SharedModelsInterface

final class HomeViewController: BaseViewController {
    private let viewModel: HomeViewModel
    private var cancellables = Set<AnyCancellable>()
    private var videos: [Video] = []

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = AppTheme.background
        cv.dataSource = self
        cv.delegate = self
        cv.prefetchDataSource = self
        cv.register(VideoThumbnailCell.self, forCellWithReuseIdentifier: VideoThumbnailCell.reuseIdentifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.tintColor = AppTheme.secondary
        rc.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        return rc
    }()

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindState()
        viewModel.action.send(.viewDidLoad)
    }

    private func setupUI() {
        view.backgroundColor = AppTheme.background
        title = "Pexels"

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: AppTheme.primaryText
        ]
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: AppTheme.primaryText
        ]

        view.addSubview(collectionView)
        collectionView.pinToEdges(of: view)
        collectionView.refreshControl = refreshControl
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let spacing: CGFloat = 1.5
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / 3.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: spacing / 2, leading: spacing / 2, bottom: spacing / 2, trailing: spacing / 2)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0 / 3.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item, item])

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func bindState() {
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)
    }

    private func render(_ state: HomeViewModel.State) {
        switch state {
        case .idle:
            break
        case .loading:
            if videos.isEmpty {
                showLoading(true)
            }
        case .loaded(let newVideos):
            showLoading(false)
            refreshControl.endRefreshing()
            videos = newVideos
            collectionView.reloadData()
        case .error(let message):
            showLoading(false)
            refreshControl.endRefreshing()
            showErrorAlert(message: message)
        }
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.viewModel.action.send(.viewDidLoad)
        })
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func didPullToRefresh() {
        viewModel.action.send(.pullToRefresh)
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoThumbnailCell.reuseIdentifier,
            for: indexPath
        ) as? VideoThumbnailCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: videos[indexPath.item])
        return cell
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.action.send(.didSelectVideo(index: indexPath.item))
    }
}

extension HomeViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let maxIndex = indexPaths.map(\.item).max() ?? 0
        if maxIndex >= videos.count - 6 {
            viewModel.action.send(.loadMore)
        }
    }
}
