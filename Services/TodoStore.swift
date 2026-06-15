import Foundation

extension Notification.Name {
    /// 待办数据发生变更（增/删/改）时发布，VC 订阅后刷新列表。
    static let todosDidChange = Notification.Name("TodoStore.todosDidChange")
    /// 分类数据发生变更时发布。
    static let categoriesDidChange = Notification.Name("TodoStore.categoriesDidChange")
}

/// 业务真相源。封装所有待办/分类的数据操作，对 VC 暴露简单接口。
/// VC 不直接接触 Storage；数据变更通过通知广播驱动 UI 刷新。
final class TodoStore {

    static let shared = TodoStore()

    private let storage: TodoStorage

    init(storage: TodoStorage = CoreDataTodoStorage()) {
        self.storage = storage
    }

    // MARK: - 查询

    /// 按筛选条件 + 排序拉取待办。
    func todos(filter: TodoFilter = .none, sort: TodoSortOption = .createdAtDescending) -> [Todo] {
        storage.fetchTodos(predicate: filter.makePredicate(), sortBy: sort.sortDescriptors)
    }

    func categories() -> [Category] {
        storage.fetchAllCategories()
    }

    // MARK: - 待办增删改

    /// 新建或更新待办。更新时自动刷新 updatedAt。
    func upsert(_ todo: Todo) {
        var todo = todo
        todo.updatedAt = Date()
        storage.saveTodo(todo)
        NotificationService.shared.schedule(for: todo)
        notifyTodosChanged()
    }

    func delete(todoId: String) {
        storage.deleteTodo(id: todoId)
        NotificationService.shared.cancel(todoId: todoId)
        notifyTodosChanged()
    }

    /// 切换完成状态。
    func toggleCompletion(_ todo: Todo) {
        var updated = todo
        updated.isCompleted.toggle()
        updated.updatedAt = Date()
        storage.saveTodo(updated)
        // 完成则取消提醒，未完成则（重新）调度
        NotificationService.shared.schedule(for: updated)
        notifyTodosChanged()
    }

    // MARK: - 分类增删改

    func upsert(_ category: Category) {
        storage.saveCategory(category)
        notifyCategoriesChanged()
    }

    func delete(categoryId: String) {
        storage.deleteCategory(id: categoryId)
        // 删除分类会把关联待办归为未分类，两者都需刷新
        notifyCategoriesChanged()
        notifyTodosChanged()
    }

    // MARK: - 通知

    private func notifyTodosChanged() {
        NotificationCenter.default.post(name: .todosDidChange, object: nil)
    }

    private func notifyCategoriesChanged() {
        NotificationCenter.default.post(name: .categoriesDidChange, object: nil)
    }
}
