import UIKit
import LocalAuthentication
class AuthenticationServices {
    static private var authenticationContext = LAContext()
    static func askForUserAuth(_ viewController: UIViewController, completionHandler: @escaping (Bool) -> Void) {
        var touchIDError: NSError?
        guard self.authenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &touchIDError) else {
            showAlertWithTitle(viewController, title: "Error", message: "This device does not allow authentication.")
            completionHandler(false)
            return
        }
        self.authenticationContext.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Cancel help occurence") {
                (success, _error) in
                if let error = _error {
                    if let laError = error as? LAError {
                        let message = self.errorMessageForLAErrorCode(errorCode: laError.code.rawValue)
                        print("Authentication error: \(message)")
                    } else {
                        print("Authentication error: Unidentified error")
                    }
                    completionHandler(false)
                } else {
                    print("Authentication recognized.")
                    completionHandler(true)
                }
                self.resetAuthContext()
        }
    }
    static func resetAuthContext() {
        self.authenticationContext.invalidate()
        self.authenticationContext = LAContext()
    }
    static func showAlertWithTitle(_ viewController: UIViewController, title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertVC.addAction(okAction)
        DispatchQueue.main.async() {
            () in
            viewController.present(alertVC, animated: true, completion: nil)
        }
    }
    static func errorMessageForLAErrorCode(errorCode: Int) -> String {
        var message = ""
        switch errorCode {
        case LAError.appCancel.rawValue:
            message = "Authentication was cancelled by application"
        case LAError.authenticationFailed.rawValue:
            message = "The user failed to provide valid credentials"
        case LAError.invalidContext.rawValue:
            message = "The context is invalid"
        case LAError.passcodeNotSet.rawValue:
            message = "Passcode is not set on the device"
        case LAError.systemCancel.rawValue:
            message = "Authentication was cancelled by the system"
        case LAError.touchIDLockout.rawValue:
            message = "Too many failed attempts."
        case LAError.touchIDNotAvailable.rawValue:
            message = "TouchID is not available on the device"
        case LAError.userCancel.rawValue:
            message = "Authentication process was cancelled by the user"
        case LAError.userFallback.rawValue:
            message = "The user chose to use the fallback"
        default:
            message = "Did not find error code on LAError object"
        }
        return message
    }
}
