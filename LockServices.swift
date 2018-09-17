import UIKit
class LockServices: NSObject {
    static func setLockMode(){
        UserDefaults.standard.set(true, forKey: "lock")
    }
    static func checkLockMode() -> Bool? {
        if let islock = UserDefaults.standard.object(forKey: "lock") as? Bool {
            return islock
        }
        return nil
    }
	func getCurrentDate() -> String {
		let date = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"
		let dateString = dateFormatter.string(from: date)
		return dateString
	}
    static func dismissLockMode(){
        UserDefaults.standard.set(false, forKey: "lock")
    }
}
