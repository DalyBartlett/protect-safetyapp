import UIKit
class TimerDetailsViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        setTimerText(timeString: AppSettings.mainUser!.arrivalInformation!.timer.timeString)
        AppSettings.mainUser!.arrivalInformation!.timer.delegate = self
    }
    override func viewWillDisappear(_ animated: Bool) {
        if let userTimer = AppSettings.mainUser!.arrivalInformation?.timer {
            userTimer.delegate = nil
        }
    }
    @IBAction func dismissTimerButton() {
        if AppSettings.mainUser!.arrivalInformation != nil {
            AppSettings.mainUser!.arrivalInformation = nil
        }
        dismissTimer()
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func snoozeButton() {
        if let userTimer = AppSettings.mainUser!.arrivalInformation?.timer {
            userTimer.addTime(timeInSecs: 5*60)
        }
    }
}
extension TimerDetailsViewController: TimerObjectDelegate {
    func setTimerText(timeString: String) {
        if timeLabel.isHidden == true {
            timeLabel.isHidden = false
        }
        timeLabel.text = timeString
    }
    func updateTimerText(timeString: String) {
        timeLabel.text = timeString
    }
    func displayAlert() {
        let alertController = UIAlertController(title: "Have you arrived?",
                                                message: nil,
                                                preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Yes",
                                                style: UIAlertActionStyle.cancel,
                                                handler: { action in
                                                    AppSettings.mainUser!.arrived()
        }))
        alertController.addAction(UIAlertAction(title: "+5 min",
                                                style: UIAlertActionStyle.default,
                                                handler: { action in
                                                    AppSettings.mainUser!.arrivalInformation!.timer.addTime(timeInSecs: 5*60)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    func dismissTimer() {
        timeLabel.text = "00:00:00"
    }
}
