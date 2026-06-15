import UIKit

/// 列表为空时的占位视图：图标 + 提示文案。
final class EmptyStateView: UIView {

    private let imageView = UIImageView()
    private let label = UILabel()

    var message: String = "" {
        didSet { label.text = message }
    }

    init(message: String = "暂无待办，点击右上角「+」新建") {
        super.init(frame: .zero)
        setupUI(message: message)
        self.message = message
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI(message: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .light)
        imageView.image = UIImage(systemName: "checklist", withConfiguration: config)
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        label.text = message
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
        ])
    }
}
