import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    private var permissionRequested = false

    func requestPermissionIfNeeded() {
        guard !permissionRequested else { return }
        permissionRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyBlockComplete(title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Block complete"
        content.body = title
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "timeblock.complete.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
