import UIKit

/// 主列表页：展示全部待办，支持勾选完成、左滑删除、新建/编辑跳转。
final class TodoListViewController: UIViewController {

    private let store = TodoStore.shared
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateView = EmptyStateView()

    private var todos: [Todo] = []
    private var sortOption: TodoSortOption = .createdAtDescending
    private var filter: TodoFilter = .none
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "待办"
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupSearch()
        setupTableView()
        setupEmptyState()
        observeStoreChanges()
        reload()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            sortFilterBarButton(),
        ]
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "folder"), style: .plain,
            target: self, action: #selector(manageCategoriesTapped))
    }

    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索标题"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    /// 排序 + 分类筛选下拉菜单
    private func sortFilterBarButton() -> UIBarButtonItem {
        let sortMenu = UIMenu(title: "排序", options: .displayInline, children: [
            menuAction("创建时间", .createdAtDescending),
            menuAction("截止时间", .dueDateAscending),
            menuAction("优先级", .priorityDescending),
        ])
        var categoryChildren: [UIAction] = [
            UIAction(title: "全部分类", state: filter.categoryId == nil ? .on : .off) { [weak self] _ in
                self?.filter.categoryId = nil
                self?.reloadAndRebuildMenu()
            }
        ]
        for category in store.categories() {
            categoryChildren.append(
                UIAction(title: category.name, state: filter.categoryId == category.id ? .on : .off) { [weak self] _ in
                    self?.filter.categoryId = category.id
                    self?.reloadAndRebuildMenu()
                })
        }
        let categoryMenu = UIMenu(title: "分类筛选", options: .displayInline, children: categoryChildren)
        let menu = UIMenu(title: "", children: [sortMenu, categoryMenu])
        return UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), menu: menu)
    }

    private func menuAction(_ title: String, _ option: TodoSortOption) -> UIAction {
        UIAction(title: title, state: sortOption == option ? .on : .off) { [weak self] _ in
            self?.sortOption = option
            self?.reloadAndRebuildMenu()
        }
    }

    private func reloadAndRebuildMenu() {
        reload()
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            sortFilterBarButton(),
        ]
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TodoCell.self, forCellReuseIdentifier: TodoCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func observeStoreChanges() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(reload),
            name: .todosDidChange, object: nil)
    }

    // MARK: - Data

    @objc private func reload() {
        todos = store.todos(filter: filter, sort: sortOption)
        tableView.reloadData()
        let isEmpty = todos.isEmpty
        emptyStateView.message = filter.isEmpty
            ? "暂无待办，点击右上角「+」新建"
            : "没有符合条件的待办"
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    // MARK: - Actions

    @objc private func manageCategoriesTapped() {
        navigationController?.pushViewController(CategoryListViewController(), animated: true)
    }

    @objc private func addTapped() {
        let detail = TodoDetailViewController(mode: .create)
        let nav = UINavigationController(rootViewController: detail)
        present(nav, animated: true)
    }

    private func openDetail(for todo: Todo) {
        let detail = TodoDetailViewController(mode: .edit(todo))
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension TodoListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        todos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TodoCell.reuseId, for: indexPath) as! TodoCell
        let todo = todos[indexPath.row]
        cell.configure(with: todo)
        cell.onToggle = { [weak self] in
            self?.store.toggleCompletion(todo)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TodoListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openDetail(for: todos[indexPath.row])
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let todo = todos[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            self?.store.delete(todoId: todo.id)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - UISearchResultsUpdating

extension TodoListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        filter.keyword = (text?.isEmpty ?? true) ? nil : text
        reload()
    }
}
