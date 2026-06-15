import UIKit

/// 分类管理页：列出全部分类，支持新增、删除。
final class CategoryListViewController: UIViewController {

    private let store = TodoStore.shared
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var categories: [Category] = []

    /// 预设颜色池，新增分类时轮流取用。
    private let palette = ["#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#007AFF", "#5856D6", "#AF52DE"]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "分类管理"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        setupTableView()
        observeChanges()
        reload()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func observeChanges() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(reload), name: .categoriesDidChange, object: nil)
    }

    @objc private func reload() {
        categories = store.categories()
        tableView.reloadData()
    }

    @objc private func addTapped() {
        let alert = UIAlertController(title: "新增分类", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "分类名称" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "添加", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let name = (alert.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            let color = self.palette[self.categories.count % self.palette.count]
            self.store.upsert(Category(name: name, colorHex: color))
        })
        present(alert, animated: true)
    }
}

extension CategoryListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = categories[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = category.name
        config.image = UIImage(systemName: "circle.fill")
        config.imageProperties.tintColor = UIColor(hexString: category.colorHex)
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let category = categories[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            self?.store.delete(categoryId: category.id)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
