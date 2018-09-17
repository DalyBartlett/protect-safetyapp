import UIKit
class PlaceCell: UITableViewCell {
    @IBOutlet weak var placePin: UIImageView!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var placeAddress: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
