import UIKit
import UserNotifications
class NotificationServices: NSObject {
	override init() {
		super.init()
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                if granted {
                    print("Notification Allowed")
                }
                if (error != nil) {
                    print(error?.localizedDescription)
                }
            }
        } else {
        }
	}
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
    static func sendHelpNotification () {
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.title = "Ajuda requisitada!"
            content.body = "Um protegido seu pediu sua ajuda, procure entender a situação e ajudá-lo"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3.0, repeats: false)
            let notificationRequest = UNNotificationRequest(identifier: "help", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(notificationRequest){
                (error) in
                if error != nil {
                    print("Error in adding notification request")
                }
            }
        } else {
        }
	}
	@objc func handleNotification (notification: Notification) {
	}
}
extension Notification.Name {
	static let helpNotification = Notification.Name("helpNotificationWithId:ID")
}
