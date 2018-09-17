import UIKit
import FBSDKLoginKit
import FirebaseAuth
class LoginViewController: UIViewController {
    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var logoTypo: UIImageView!
    @IBOutlet weak var topImageConstraint: NSLayoutConstraint!
    var loginButton:FBSDKLoginButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setFBLoginButton()
        self.handleFacebookStatus()
        logoTypo.alpha = 0.0
        UIView.animate(withDuration: 1.0, animations: {
            self.logoImage.center.y -= 81
        }, completion: {(success) in
            UIView.animate(withDuration: 0.7, animations: {
                self.logoTypo.alpha = 1.0
            }, completion: {(success) in
                self.loginButton.fadeIn(withDuration: 0.7)
            })
        })
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    func setFBLoginButton() {
        self.loginButton = FBSDKLoginButton()
        self.loginButton.readPermissions = ["public_profile", "email"]
        self.loginButton.delegate = self
        loginButton.alpha = 0.0
        view.addSubview(self.loginButton)
        loginButton.frame = CGRect(x: 16, y: logoTypo.frame.maxY + 116, width: view.frame.width - 32, height: 42)
    }
}
extension LoginViewController: FBSDKLoginButtonDelegate {
    func handleFacebookStatus() {
        if (FBSDKAccessToken.current() != nil) {
            self.userDidLogIn()
        }
    }
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        guard (error == nil) else {
            print("Error on clicking facebook login button.")
            return
        }
        if result.isCancelled {
            print("Facebook login has been cancelled.")
            return
        }
        self.userDidLogIn()
    }
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("App did log out of facebook.")
        LoginServices.handleUserLoggedOut()
    }
    func userDidLogIn() {
        LoginServices.handleUserLoggedIn {
            (successful) in
            guard (successful == true) else {
                print("Couldn't fetch user's facebook or database information.")
                return
            }
            print("Login successful")
            self.performSegue(withIdentifier: "NavigateViewController", sender: nil)
        }
    }
}
extension UIView {
    func fadeIn(withDuration duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }
    func fadeOut(withDuration duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }
}
