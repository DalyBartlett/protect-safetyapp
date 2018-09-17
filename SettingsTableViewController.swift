import UIKit
import Nuke
class SettingsTableViewController: UITableViewController {
    @IBOutlet weak var mainUserName: UILabel!
    @IBOutlet weak var mainUserEmail: UILabel!
    @IBOutlet weak var mainUserPicture: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let mainUser = AppSettings.mainUser
        self.mainUserName.text = mainUser?.name
        self.mainUserEmail.text = mainUser?.email
        self.mainUserPicture.layer.cornerRadius = (self.mainUserPicture.frame.height)/2
        self.mainUserPicture.backgroundColor = UIColor.lightGray
        self.mainUserPicture.image = UIImage(named: "collectionview_placeholder_image")
        Manager.shared.loadImage(with: AppSettings.mainUser!.profilePictureURL, into: self.mainUserPicture)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1{
            let text = "Melhore a sua segurança e de todos ao seu redor, confira Protect para o seu smartphone. Baixe:"
            let activityViewController = UIActivityViewController(activityItems: [text as NSString], applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
}
