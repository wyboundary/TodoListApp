import Foundation

/// 列表排序方式
enum TodoSortOption: Equatable {
    case createdAtDescending   // 创建时间倒序（默认）
    case dueDateAscending      // 截止时间正序（早的在前，无截止时间排最后）
    case priorityDescending    // 优先级高 -> 低

    /// 排序描述符。所有排序均以「未完成优先」为首要规则，使完成项沉底。
    var sortDescriptors: [NSSortDescriptor] {
        let completedLast = NSSortDescriptor(key: "isCompleted", ascending: true)
        switch self {
        case .createdAtDescending:
            return [completedLast,
                    NSSortDescriptor(key: "createdAt", ascending: false)]
        case .dueDateAscending:
            // dueDate 为 nil 的排最后
            return [completedLast,
                    NSSortDescriptor(key: "dueDate", ascending: true),
                    NSSortDescriptor(key: "createdAt", ascending: false)]
        case .priorityDescending:
            return [completedLast,
                    NSSortDescriptor(key: "priority", ascending: false),
                    NSSortDescriptor(key: "createdAt", ascending: false)]
        }
    }
}

/// 列表筛选条件
struct TodoFilter {
    var categoryId: String?    // nil = 全部分类
    var keyword: String?       // 标题关键词搜索

    static let none = TodoFilter()

    var isEmpty: Bool {
        (categoryId == nil) && (keyword?.isEmpty ?? true)
    }

    func makePredicate() -> NSPredicate? {
        var predicates: [NSPredicate] = []
        if let categoryId = categoryId {
            predicates.append(NSPredicate(format: "categoryId == %@", categoryId))
        }
        if let keyword = keyword, !keyword.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@", keyword))
        }
        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
