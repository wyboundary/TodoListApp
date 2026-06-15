import Foundation

/// 待办事项数据模型（纯值类型，与持久化实体解耦）。
struct Todo: Identifiable, Equatable, Codable {
    let id: String
    var title: String
    var notes: String?
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var categoryId: String?
    let createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString,
         title: String,
         notes: String? = nil,
         isCompleted: Bool = false,
         priority: Priority = .medium,
         dueDate: Date? = nil,
         categoryId: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDate = dueDate
        self.categoryId = categoryId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
