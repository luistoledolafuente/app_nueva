import Foundation
import UIKit
import UserNotifications

class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func scheduleLowStockAlert(productName: String, stock: Int, codigo: String) {
        let stockAlertsEnabled = UserDefaults.standard.object(forKey: "stockAlerts") as? Bool ?? true
        guard stockAlertsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Stock bajo"
        content.body = "\(productName) — Stock: \(stock) unidades"
        content.sound = .default

        let identifier = "lowstock_\(codigo)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDailyStockCheck() {
        let remindersEnabled = UserDefaults.standard.object(forKey: "reminders") as? Bool ?? false
        guard remindersEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Revisión de inventario"
        content.body = "Revisa los productos con stock bajo en tu tienda"
        content.sound = .default

        var components = DateComponents()
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_stock_check", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
