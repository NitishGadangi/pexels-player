import UIKit
import UIComponents

final class SavedItemsViewController: BaseViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Saved Items"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = AppTheme.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "This feature is currently under development."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = AppTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        title = "Saved"

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: AppTheme.primaryText
        ]
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: AppTheme.primaryText
        ]

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }
}
