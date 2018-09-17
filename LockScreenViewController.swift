import UIKit
class LockScreenViewController: UIViewController {
    @IBOutlet weak var stopButton: UIButton!
    weak var helpViewController: HelpViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func stopButtonPressed() {
        self.stopButton.isEnabled = false
        AuthenticationServices.askForUserAuth(self) {
            (success) in
            self.stopButton.isEnabled = true
            guard success else {
                print("Authentication unsuccessful")
                return
            }
            LockServices.dismissLockMode()
            let date = self.getCurrentDate()
            DatabaseManager.removeHelpOccurrence(date: date, completionHandler: {
                (error) in
                if error != nil {
                    print("Error on dismissing timer")
                    return
                }
            })
            AppSettings.mainUser?.status = userStatus.safe
            DatabaseManager.updateUserSatus() {
                (error) in
                guard error == nil else {
                    print("Error on dismissing timer")
                    return
                }
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    func getCurrentDate() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
}
