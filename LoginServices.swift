import Foundation
import FBSDKLoginKit
import FirebaseAuth
class LoginServices {
    static func handleUserLoggedIn(completionHandler: @escaping (Bool) -> Void) {
        LoginServices.fetchFacebookUserInfo {
            (userID, userName, userEmail, error) in
            guard (error == nil) else {
                print("Error on fetching user info from facebook.")
                FBSDKLoginManager().logOut()
                completionHandler(false)
                return
            }
            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            Auth.auth().signIn(with: credential) {
                (_, error) in
                guard (error == nil) else {
                    print("Error on signing user into firebase.")
                    return
                }
                DatabaseManager.fetchUser(userID: userID!) {
                    (user) in
                    if (user != nil) {
                        AppSettings.mainUser = user
                        completionHandler(true)
                        return
                    }
                    let mainUser = MainUser(id: userID!, name: userName!, email: userEmail, phoneNumber: nil, status: userStatus.safe)
                    DatabaseManager.addUser(mainUser) {
                        (error) in
                        guard (error == nil) else {
                            print("Couldn't add user to database")
                            FBSDKLoginManager().logOut()
                            completionHandler(false)
                            return
                        }
                        print("DONE---------------------------------------------------------")
                        AppSettings.mainUser = mainUser
                        completionHandler(true)
                        return
                    }
                }
            }
        }
    }
    static func handleUserLoggedOut() {
        AppSettings.mainUser = nil
    }
    static func fetchFacebookUserInfo(completionHandler: @escaping (String?, String?, String?, Error?) -> Void) {
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start {
            (connection, result, error) in
            guard connection != nil else {
                print("No connection to internet.")
                completionHandler(nil, nil, nil, nil)
                return
            }
            guard error == nil else {
                print("Error fetching user's facebook information.")
                completionHandler(nil, nil, nil, error)
                return
            }
            guard result != nil else {
                print("Facebook information is nil.")
                completionHandler(nil, nil, nil, nil)
                return
            }
            let userInfo = (result as! [String:Any])
            let userID = userInfo["id"] as! String
            let userName = userInfo["name"] as! String
            let userEmail = userInfo["email"] as! String
            completionHandler(userID, userName, userEmail, nil)
        }
    }
}
