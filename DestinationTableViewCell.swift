import UIKit
class DestinationTableViewCell: UITableViewCell {
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var city: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
