import Foundation
import UserNotifications

/// 本地通知服务：为有截止时间的待办调度到期提醒。
final class NotificationService {

    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// 请求通知权限（首次使用时调用）。
    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self?.center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    /// 为待办调度到期提醒。重复调用会先取消旧通知再重建（用 todo.id 作为标识）。
    /// 无截止时间、已完成、或时间已过的待办不调度。
    func schedule(for todo: Todo) {
        cancel(todoId: todo.id)

        guard !todo.isCompleted, let due = todo.dueDate, due > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "待办到期"
        content.body = todo.title
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: due)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: todo.id, content: content, trigger: trigger)
        center.add(request)
    }

    func cancel(todoId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [todoId])
    }
}
