import CoreData

/// Core Data 栈封装。加载名为 "TodoModel" 的持久化容器。
final class CoreDataStack {

    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "TodoModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                // 加载失败属于不可恢复的开发期错误（模型不匹配等），直接崩溃便于定位。
                fatalError("Core Data 加载失败: \(error)")
            }
        }
        // 合并策略：以内存中对象为准，配合 id 唯一约束实现 upsert。
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext { container.viewContext }
}
