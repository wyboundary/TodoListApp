import UIKit

/// 待办列表 Cell：勾选框 + 标题 + 截止时间 + 优先级色条。
final class TodoCell: UITableViewCell {

    static let reuseId = "TodoCell"

    /// 点击勾选框回调
    var onToggle: (() -> Void)?

    private let checkButton = UIButton(type: .system)
    private let priorityBar = UIView()
    private let titleLabel = UILabel()
    private let dueDateLabel = UILabel()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .none

        priorityBar.translatesAutoresizingMaskIntoConstraints = false
        priorityBar.layer.cornerRadius = 2
        contentView.addSubview(priorityBar)

        checkButton.translatesAutoresizingMaskIntoConstraints = false
        checkButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        contentView.addSubview(checkButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)

        dueDateLabel.translatesAutoresizingMaskIntoConstraints = false
        dueDateLabel.font = .systemFont(ofSize: 12)
        dueDateLabel.textColor = .secondaryLabel
        contentView.addSubview(dueDateLabel)

        NSLayoutConstraint.activate([
            priorityBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            priorityBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            priorityBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            priorityBar.widthAnchor.constraint(equalToConstant: 4),

            checkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkButton.widthAnchor.constraint(equalToConstant: 28),
            checkButton.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: checkButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            dueDateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dueDateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            dueDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dueDateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    func configure(with todo: Todo) {
        titleLabel.text = todo.title

        // 完成态：标题置灰 + 删除线
        if todo.isCompleted {
            titleLabel.attributedText = NSAttributedString(
                string: todo.title,
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue,
                             .foregroundColor: UIColor.secondaryLabel])
            checkButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            checkButton.tintColor = .systemGreen
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = todo.title
            titleLabel.textColor = .label
            checkButton.setImage(UIImage(systemName: "circle"), for: .normal)
            checkButton.tintColor = .systemGray3
        }

        // 截止时间
        if let due = todo.dueDate {
            dueDateLabel.text = Self.dateFormatter.string(from: due)
            dueDateLabel.textColor = (!todo.isCompleted && due < Date()) ? .systemRed : .secondaryLabel
        } else {
            dueDateLabel.text = nil
        }

        priorityBar.backgroundColor = todo.priority.color
    }

    @objc private func toggleTapped() {
        onToggle?()
    }
}
