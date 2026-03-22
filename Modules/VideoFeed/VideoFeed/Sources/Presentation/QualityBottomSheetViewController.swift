import UIKit
import UIComponents
import SharedModelsInterface

final class QualityBottomSheetViewController: UIViewController {
    private let videoFiles: [VideoFile]
    private let currentQuality: VideoQuality
    private let onSelect: (VideoQuality) -> Void

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        tv.dataSource = self
        tv.delegate = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "QualityCell")
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Video Quality"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var qualities: [(quality: VideoQuality, file: VideoFile)] = []

    init(videoFiles: [VideoFile], currentQuality: VideoQuality, onSelect: @escaping (VideoQuality) -> Void) {
        self.videoFiles = videoFiles
        self.currentQuality = currentQuality
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        buildQualityList()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        setupViews()
    }

    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func buildQualityList() {
        let mp4Files = videoFiles.filter { $0.fileType == "video/mp4" }
        var seen = Set<String>()
        for file in mp4Files {
            guard !seen.contains(file.quality),
                  let quality = VideoQuality(rawValue: file.quality) else { continue }
            seen.insert(file.quality)
            qualities.append((quality, file))
        }
        qualities.sort { lhs, rhs in
            let order: [VideoQuality] = [.sd, .hd, .uhd, .hls]
            let li = order.firstIndex(of: lhs.quality) ?? 0
            let ri = order.firstIndex(of: rhs.quality) ?? 0
            return li < ri
        }
    }
}

extension QualityBottomSheetViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        qualities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QualityCell", for: indexPath)
        let entry = qualities[indexPath.row]
        let file = entry.file

        var parts = [entry.quality.displayName]
        if let w = file.width, let h = file.height {
            parts.append("\(w)x\(h)")
        }
        if let fps = file.fps {
            parts.append("\(Int(fps)) fps")
        }
        cell.textLabel?.text = parts.joined(separator: " - ")
        cell.textLabel?.textColor = .white
        cell.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        cell.accessoryType = entry.quality == currentQuality ? .checkmark : .none
        cell.tintColor = AppTheme.accent
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = qualities[indexPath.row].quality
        dismiss(animated: true) { [weak self] in
            self?.onSelect(selected)
        }
    }
}
