import UIKit
class TimerCellTableViewCell: UITableViewCell, DestinationArrivalTimeDataSource {
    func getDestinationTime() -> TimeInterval {
        return self.timer.countDownDuration
    }
    @IBOutlet weak var timer: UIDatePicker!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
