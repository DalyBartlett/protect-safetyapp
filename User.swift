import UIKit
import CoreLocation
struct userStatus {
	static let safe = "Safe"
	static let arriving = "Arriving in"
	static let danger = "In Danger!"
}
protocol UserStatusDelegate {
    func refreshStatus()
}
class User {
    var id: String
    var name: String
    var email: String
    var phoneNumber: String
    var profilePictureURL: URL
    var statusDelegate: UserStatusDelegate?
    var status: String {
        didSet {
            if self.statusDelegate != nil {
                self.statusDelegate?.refreshStatus()
            }
        }
    }
	init(id: String, name: String, email: String?, phoneNumber: String?, status: String) {
        self.id = id
        self.name = name
		self.status = status
        if let email = email {
            self.email = email
        } else {
            self.email = ""
        }
        if let phoneNumber = phoneNumber {
            self.phoneNumber = phoneNumber
        } else {
            self.phoneNumber = ""
        }
        self.profilePictureURL = URL(string: "https://graph.facebook.com/\(id)/picture?type=large&return_ssl_resources=1")!
    }
}
