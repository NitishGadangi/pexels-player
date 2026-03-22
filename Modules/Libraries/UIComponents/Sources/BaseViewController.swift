import UIKit

open class BaseViewController: UIViewController {
    private lazy var loadingView = LoadingView()

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLoadingView()
    }

    private func setupLoadingView() {
        view.addSubview(loadingView)
        loadingView.pinToEdges(of: view)
        loadingView.isHidden = true
    }

    public func showLoading(_ show: Bool) {
        loadingView.isHidden = !show
        if show {
            view.bringSubviewToFront(loadingView)
        }
    }
}
