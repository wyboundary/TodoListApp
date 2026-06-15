import Foundation

/// 分类数据模型（纯值类型）。
/// 待办通过 categoryId 弱关联分类；删除分类时待办归为「未分类」(categoryId = nil)。
struct Category: Identifiable, Equatable, Codable {
    let id: String
    var name: String
    var colorHex: String
    let createdAt: Date

    init(id: String = UUID().uuidString,
         name: String,
         colorHex: String,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}
