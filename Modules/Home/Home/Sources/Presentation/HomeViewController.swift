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
        cv.register(LoadingFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: LoadingFooterView.reuseIdentifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private var isLoadingMore = false


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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func setupUI() {
        view.backgroundColor = AppTheme.background
        title = "Pexels"
        navigationItem.largeTitleDisplayMode = .always

        view.addSubview(collectionView)
        collectionView.pinToEdges(of: view)
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

        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
        section.boundarySupplementaryItems = [footer]

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
            isLoadingMore = false
            videos = newVideos
            collectionView.reloadData()
        case .error(let message):
            showLoading(false)
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
        if maxIndex >= videos.count - 3 {
            isLoadingMore = true
            collectionView.reloadData()
            viewModel.action.send(.loadMore)
        }
    }
}

extension HomeViewController {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter,
              let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LoadingFooterView.reuseIdentifier,
                for: indexPath
              ) as? LoadingFooterView else {
            return UICollectionReusableView()
        }
        footer.setLoading(isLoadingMore && !videos.isEmpty)
        return footer
    }
}

private final class LoadingFooterView: UICollectionReusableView {
    static let reuseIdentifier = "LoadingFooterView"

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.color = AppTheme.secondary
        s.translatesAutoresizingMaskIntoConstraints = false
        s.hidesWhenStopped = true
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(spinner)
        spinner.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLoading(_ loading: Bool) {
        if loading { spinner.startAnimating() } else { spinner.stopAnimating() }
    }
}
