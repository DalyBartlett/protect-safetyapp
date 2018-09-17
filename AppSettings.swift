import Foundation
class AppSettings {
    static var mainUser: MainUser? = nil {
        didSet {
            DatabaseManager.addObserverToUserProtecteds()
        }
    }
}
