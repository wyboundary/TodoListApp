import CoreData

/// Core Data 持久化实现。负责 Todo/Category 值类型与 CDTodo/CDCategory 实体的双向转换。
final class CoreDataTodoStorage: TodoStorage {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    // MARK: - Todo

    func fetchAllTodos() -> [Todo] {
        fetchTodos(predicate: nil, sortBy: [NSSortDescriptor(key: "createdAt", ascending: false)])
    }

    func fetchTodos(predicate: NSPredicate?, sortBy: [NSSortDescriptor]) -> [Todo] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDTodo")
        request.predicate = predicate
        request.sortDescriptors = sortBy
        let objects = (try? context.fetch(request)) ?? []
        return objects.map { todo(from: $0) }
    }

    func saveTodo(_ todo: Todo) {
        let object = existingObject(entity: "CDTodo", id: todo.id)
            ?? NSEntityDescription.insertNewObject(forEntityName: "CDTodo", into: context)
        apply(todo, to: object)
        saveContext()
    }

    func deleteTodo(id: String) {
        guard let object = existingObject(entity: "CDTodo", id: id) else { return }
        context.delete(object)
        saveContext()
    }

    // MARK: - Category

    func fetchAllCategories() -> [Category] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDCategory")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let objects = (try? context.fetch(request)) ?? []
        return objects.map { category(from: $0) }
    }

    func saveCategory(_ category: Category) {
        let object = existingObject(entity: "CDCategory", id: category.id)
            ?? NSEntityDescription.insertNewObject(forEntityName: "CDCategory", into: context)
        object.setValue(category.id, forKey: "id")
        object.setValue(category.name, forKey: "name")
        object.setValue(category.colorHex, forKey: "colorHex")
        object.setValue(category.createdAt, forKey: "createdAt")
        saveContext()
    }

    func deleteCategory(id: String) {
        guard let object = existingObject(entity: "CDCategory", id: id) else { return }
        context.delete(object)
        // 关联待办归为「未分类」
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDTodo")
        request.predicate = NSPredicate(format: "categoryId == %@", id)
        let related = (try? context.fetch(request)) ?? []
        related.forEach { $0.setValue(nil, forKey: "categoryId") }
        saveContext()
    }

    // MARK: - 转换：实体 -> Model

    private func todo(from object: NSManagedObject) -> Todo {
        Todo(
            id: object.value(forKey: "id") as? String ?? "",
            title: object.value(forKey: "title") as? String ?? "",
            notes: object.value(forKey: "notes") as? String,
            isCompleted: object.value(forKey: "isCompleted") as? Bool ?? false,
            priority: Priority(rawValue: Int(object.value(forKey: "priority") as? Int16 ?? 1)) ?? .medium,
            dueDate: object.value(forKey: "dueDate") as? Date,
            categoryId: object.value(forKey: "categoryId") as? String,
            createdAt: object.value(forKey: "createdAt") as? Date ?? Date(),
            updatedAt: object.value(forKey: "updatedAt") as? Date ?? Date()
        )
    }

    private func category(from object: NSManagedObject) -> Category {
        Category(
            id: object.value(forKey: "id") as? String ?? "",
            name: object.value(forKey: "name") as? String ?? "",
            colorHex: object.value(forKey: "colorHex") as? String ?? "#999999",
            createdAt: object.value(forKey: "createdAt") as? Date ?? Date()
        )
    }

    // MARK: - 转换：Model -> 实体

    private func apply(_ todo: Todo, to object: NSManagedObject) {
        object.setValue(todo.id, forKey: "id")
        object.setValue(todo.title, forKey: "title")
        object.setValue(todo.notes, forKey: "notes")
        object.setValue(todo.isCompleted, forKey: "isCompleted")
        object.setValue(Int16(todo.priority.rawValue), forKey: "priority")
        object.setValue(todo.dueDate, forKey: "dueDate")
        object.setValue(todo.categoryId, forKey: "categoryId")
        object.setValue(todo.createdAt, forKey: "createdAt")
        object.setValue(todo.updatedAt, forKey: "updatedAt")
    }

    // MARK: - Helpers

    private func existingObject(entity: String, id: String) -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: entity)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Core Data 保存失败: \(error)")
        }
    }
}
