import UIKit

/// 待办优先级。
/// rawValue 同时作为持久化存储值与排序权重（值越大优先级越高）。
enum Priority: Int, CaseIterable, Codable {
    case low = 0
    case medium = 1
    case high = 2

    /// 列表展示文案
    var title: String {
        switch self {
        case .low:    return "低"
        case .medium: return "中"
        case .high:   return "高"
        }
    }

    /// 优先级标识颜色
    var color: UIColor {
        switch self {
        case .low:    return UIColor.systemGray
        case .medium: return UIColor.systemOrange
        case .high:   return UIColor.systemRed
        }
    }
}
