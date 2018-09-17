import UIKit
class ProtectorCellTableViewCell: UITableViewCell {
    @IBOutlet weak var protectorPic: UIImageView!
    @IBOutlet weak var protectorName: UILabel!
    @IBOutlet weak var protectorOnOff: UISwitch!
    var protectorId:String!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
