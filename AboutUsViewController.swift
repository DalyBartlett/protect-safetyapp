import UIKit
class AboutUsViewController: UIViewController {
    @IBOutlet var personView: [UIView]!
    @IBOutlet var names: [UILabel]!
    @IBOutlet var jobs: [UILabel]!
    @IBOutlet var pictures: [UIImageView]!
    @IBOutlet var personButtons: [UIButton]!
    @IBAction func andressaClicked(_ sender: UIButton) {
        self.changeFade(atIndex: 0, withDuration: 0.7)
    }
    @IBAction func filipeClicked(_ sender: UIButton) {
        self.changeFade(atIndex: 1, withDuration: 0.7)
    }
    @IBAction func pauloClicked(_ sender: UIButton) {
        self.changeFade(atIndex: 2, withDuration: 0.7)
    }
    @IBAction func rodrigoClicked(_ sender: UIButton) {
        self.changeFade(atIndex: 3, withDuration: 0.7)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0..<(personView.count) {
            let pView = personView[i]
            pView.layer.cornerRadius = 12.0
            pictures[i].layer.cornerRadius = 12.0
            names[i].alpha = 0.0
            jobs[i].alpha = 0.0
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func changeFade(atIndex index: Int, withDuration duration: TimeInterval) {
        if self.names[index].alpha == 0 {
            UIView.animate(withDuration: duration, animations: {
                self.names[index].alpha = 1.0
                self.jobs[index].alpha = 1.0
                self.pictures[index].alpha = 0.0
            })
        } else {
            UIView.animate(withDuration: duration, animations: {
                self.names[index].alpha = 0.0
                self.jobs[index].alpha = 0.0
                self.pictures[index].alpha = 1.0
            })
        }
    }
}
