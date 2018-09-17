import UIKit
import LocalAuthentication
class HelpViewController: UIViewController {
    @IBOutlet weak var clockView: ClockView!
    @IBOutlet weak var clock: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    var count: Double = 1500.0
    var totalTime: Double = 1500.0
    var countdownTimer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        count = 1500.0
        countdownTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.countdownTimer?.invalidate()
        let locked = LockServices.checkLockMode()
        if locked == true {
            let storyboard = UIStoryboard(name: "Help", bundle: nil)
            if let controller = storyboard.instantiateViewController(withIdentifier: "LockScreen") as? LockScreenViewController {
                controller.modalPresentationStyle = .fullScreen
                controller.modalTransitionStyle = .crossDissolve
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let lockViewController = segue.destination as? LockScreenViewController {
            lockViewController.helpViewController = self
        }
    }
    @objc func updateCounter() {
        if count >= 0 {
            self.clockView.currentTime = (self.count)/(self.totalTime)
            self.clock.text = "\(Int(ceil(count/100.0)))"
            self.count -= 1
        } else {
            countdownTimer?.invalidate()
        }
        if count == 0 {
            self.createHelpOccurrence()
            self.goToLockScreen()
        }
    }
    @IBAction func confirmButtonClicked() {
        self.createHelpOccurrence()
        self.goToLockScreen()
    }
    @IBAction func cancelButtonClicked() {
        self.cancelButton.isEnabled = false
        AuthenticationServices.askForUserAuth(self) {
            (success) in
            guard success else {
                self.cancelButton.isEnabled = true
                return
            }
            self.dismissView()
        }
    }
    func createHelpOccurrence () {
		LockServices.setLockMode()
		let date = self.getCurrentDate()
		let helpOccurrence = HelpOccurrence(date: date, coordinate: (AppSettings.mainUser?.lastLocation)!)
		DatabaseManager.addHelpOccurrence(helpOccurrence: helpOccurrence){
			(error) in
			guard (error == nil) else {
				print("Error on adding a new help occurrence.")
				return
			}
		}
        AppSettings.mainUser?.status = userStatus.danger
        DatabaseManager.updateUserSatus() {
            (error) in
            if error != nil {
                print("Error on dismissing timer")
                return
            }
        }
    }
    func goToLockScreen() {
        AuthenticationServices.resetAuthContext()
        if countdownTimer != nil {
            self.countdownTimer?.invalidate()
            self.countdownTimer = nil
        }
        self.dismiss(animated: true, completion: nil)
    }
    func dismissView() {
        AuthenticationServices.resetAuthContext()
        if countdownTimer != nil {
            self.countdownTimer?.invalidate()
            self.countdownTimer = nil
        }
        self.dismiss(animated: true, completion: nil)
    }
    func getCurrentDate() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yyyy   HH:mm:ss"
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
}
