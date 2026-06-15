import UIKit

/// 新建/编辑待办页。通过 mode 区分两种形态。
final class TodoDetailViewController: UIViewController {

    enum Mode {
        case create
        case edit(Todo)
    }

    private let store = TodoStore.shared
    private let mode: Mode

    /// 正在编辑的草稿（新建时为默认值）
    private var draft: Todo

    // MARK: UI
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let titleField = UITextField()
    private let notesView = UITextView()
    private let prioritySegment = UISegmentedControl(items: Priority.allCases.map { $0.title })
    private let dueSwitch = UISwitch()
    private let duePicker = UIDatePicker()
    private let categoryButton = UIButton(type: .system)

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            self.draft = Todo(title: "")
        case .edit(let todo):
            self.draft = todo
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        setupForm()
        populate()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        switch mode {
        case .create:
            title = "新建待办"
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        case .edit:
            title = "编辑待办"
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
    }

    private func setupForm() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])

        // 标题
        titleField.placeholder = "标题（必填）"
        titleField.borderStyle = .roundedRect
        titleField.font = .systemFont(ofSize: 16)
        stack.addArrangedSubview(makeSection(title: "标题", content: titleField))

        // 备注
        notesView.font = .systemFont(ofSize: 15)
        notesView.layer.borderColor = UIColor.systemGray4.cgColor
        notesView.layer.borderWidth = 1
        notesView.layer.cornerRadius = 8
        notesView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        stack.addArrangedSubview(makeSection(title: "备注", content: notesView))

        // 优先级
        stack.addArrangedSubview(makeSection(title: "优先级", content: prioritySegment))

        // 截止时间
        let dueRow = UIStackView()
        dueRow.axis = .horizontal
        dueRow.spacing = 8
        let dueLabel = UILabel()
        dueLabel.text = "设置截止时间"
        dueLabel.font = .systemFont(ofSize: 15)
        dueRow.addArrangedSubview(dueLabel)
        dueRow.addArrangedSubview(UIView())   // spacer
        dueRow.addArrangedSubview(dueSwitch)
        dueSwitch.addTarget(self, action: #selector(dueSwitchChanged), for: .valueChanged)

        duePicker.datePickerMode = .dateAndTime
        duePicker.preferredDatePickerStyle = .compact
        let dueContainer = UIStackView(arrangedSubviews: [dueRow, duePicker])
        dueContainer.axis = .vertical
        dueContainer.spacing = 8
        stack.addArrangedSubview(makeSection(title: "截止时间", content: dueContainer))

        // 分类
        categoryButton.contentHorizontalAlignment = .leading
        categoryButton.addTarget(self, action: #selector(categoryTapped), for: .touchUpInside)
        stack.addArrangedSubview(makeSection(title: "分类", content: categoryButton))

        // 删除（仅编辑态）
        if case .edit = mode {
            let deleteButton = UIButton(type: .system)
            deleteButton.setTitle("删除待办", for: .normal)
            deleteButton.setTitleColor(.systemRed, for: .normal)
            deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
            stack.addArrangedSubview(deleteButton)
        }
    }

    /// 包一层标题 + 内容的小节
    private func makeSection(title: String, content: UIView) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        let v = UIStackView(arrangedSubviews: [label, content])
        v.axis = .vertical
        v.spacing = 6
        return v
    }

    private func populate() {
        titleField.text = draft.title
        notesView.text = draft.notes
        prioritySegment.selectedSegmentIndex = draft.priority.rawValue
        if let due = draft.dueDate {
            dueSwitch.isOn = true
            duePicker.isHidden = false
            duePicker.date = due
        } else {
            dueSwitch.isOn = false
            duePicker.isHidden = true
        }
        updateCategoryButtonTitle()
    }

    private func updateCategoryButtonTitle() {
        let name = draft.categoryId
            .flatMap { id in store.categories().first { $0.id == id } }?
            .name
        categoryButton.setTitle(name ?? "未分类", for: .normal)
    }

    // MARK: - Actions

    @objc private func dueSwitchChanged() {
        duePicker.isHidden = !dueSwitch.isOn
    }

    @objc private func categoryTapped() {
        let sheet = UIAlertController(title: "选择分类", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "未分类", style: .default) { [weak self] _ in
            self?.draft.categoryId = nil
            self?.updateCategoryButtonTitle()
        })
        for category in store.categories() {
            sheet.addAction(UIAlertAction(title: category.name, style: .default) { [weak self] _ in
                self?.draft.categoryId = category.id
                self?.updateCategoryButtonTitle()
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        // iPad 适配
        sheet.popoverPresentationController?.sourceView = categoryButton
        sheet.popoverPresentationController?.sourceRect = categoryButton.bounds
        present(sheet, animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let trimmed = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            presentAlert(message: "标题不能为空")
            return
        }

        draft.title = trimmed
        draft.notes = notesView.text.isEmpty ? nil : notesView.text
        draft.priority = Priority(rawValue: prioritySegment.selectedSegmentIndex) ?? .medium
        draft.dueDate = dueSwitch.isOn ? duePicker.date : nil

        store.upsert(draft)
        close()
    }

    @objc private func deleteTapped() {
        let alert = UIAlertController(title: "删除待办", message: "确定删除「\(draft.title)」？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.store.delete(todoId: self.draft.id)
            self.close()
        })
        present(alert, animated: true)
    }

    /// 新建态为模态 -> dismiss；编辑态为 push -> pop
    private func close() {
        switch mode {
        case .create:
            dismiss(animated: true)
        case .edit:
            navigationController?.popViewController(animated: true)
        }
    }

    private func presentAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
