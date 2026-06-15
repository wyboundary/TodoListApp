import Foundation

/// 持久化层抽象。TodoStore 仅依赖此协议，便于替换实现或单测 Mock。
/// 实现类负责 Model(值类型) ↔ 持久化实体 的双向转换，NSManagedObject 不外泄。
protocol TodoStorage: AnyObject {

    // MARK: Todo
    func fetchAllTodos() -> [Todo]
    /// 按谓词查询（搜索/筛选）。predicate 为 nil 时等价 fetchAllTodos。
    func fetchTodos(predicate: NSPredicate?, sortBy: [NSSortDescriptor]) -> [Todo]
    /// upsert：id 不存在则插入，存在则更新。
    func saveTodo(_ todo: Todo)
    func deleteTodo(id: String)

    // MARK: Category
    func fetchAllCategories() -> [Category]
    func saveCategory(_ category: Category)
    /// 删除分类，并将关联待办的 categoryId 置空（归为「未分类」）。
    func deleteCategory(id: String)
}
