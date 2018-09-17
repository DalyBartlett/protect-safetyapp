import UIKit
import CoreLocation
import MapKit
import Nuke
class ProtectCollectionViewController: UICollectionViewController {
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var addProtectorButton: UIBarButtonItem!
    var protectors = [Protector]()
    var protected = [Protected]()
    var watchSessionManager: WatchSessionManager?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.watchSessionManager = WatchSessionManager()
        self.watchSessionManager?.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        AppSettings.mainUser?.protectedsDelegate = self
        self.reloadData()
    }
    override func viewWillDisappear(_ animated: Bool) {
        AppSettings.mainUser?.protectedsDelegate = nil
    }
    func reloadData() {
        self.loadActors()
        self.collectionView?.reloadData()
    }
    func loadActors() {
        if let userProtectors = AppSettings.mainUser?.protectors {
            self.protectors = userProtectors
        } else {
            self.protectors = [Protector]()
        }
        if let userProtected = AppSettings.mainUser?.protecteds {
            self.protected = userProtected
        } else {
            self.protected = [Protected]()
        }
    }
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let reuseIndex = segmentedControl.selectedSegmentIndex
        if (reuseIndex == 0) {
            return self.protectors.count
        } else {
            return self.protected.count
        }
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIndex = segmentedControl.selectedSegmentIndex
        if (reuseIndex == 0) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "protectorCell", for: indexPath) as! ProtectorCollectionViewCell
            var name = protectors[indexPath.row].name.components(separatedBy: " ")
            cell.personName.text = name.removeFirst()
            cell.profilePicture.image = UIImage(named: "collectionview_placeholder_image")
            Manager.shared.loadImage(with: protectors[indexPath.row].profilePictureURL, into: cell.profilePicture)
            cell.layer.cornerRadius = 5.0
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "protectedCell", for: indexPath) as! ProtectedCollectionViewCell
            var name = protected[indexPath.row].name.components(separatedBy: " ")
            cell.personName.text = name.removeFirst()
            cell.profilePicture.image = UIImage(named: "collectionview_placeholder_image")
            Manager.shared.loadImage(with: protected[indexPath.row].profilePictureURL, into: cell.profilePicture)
            cell.layer.cornerRadius = 5.0
            let status = protected[indexPath.row].status
            switch status {
            case userStatus.safe:
                cell.pin.image = Pin.green.image
            case userStatus.arriving:
                cell.pin.image = Pin.yellow.image
            case userStatus.danger:
                cell.pin.image = Pin.red.image
            default:
                cell.pin.image = UIImage(named: "cell_others")
            }
            return cell
        }
    }
    @IBAction func segControlChanged(_ sender: UISegmentedControl) {
        self.collectionView?.reloadData()
        self.addProtectorButton.isEnabled = !self.addProtectorButton.isEnabled
        if (self.addProtectorButton.isEnabled == true) {
            self.addProtectorButton.tintColor = UIApplication.shared.keyWindow?.tintColor
        } else {
            self.addProtectorButton.tintColor = UIColor.clear
        }
    }
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if segmentedControl.selectedSegmentIndex == 0 {
            var title  = "Protecting you: "
            if protectors[index].protectingYou == true {
                title = title + "ON"
            }
            else {
                title = title + "OFF"
            }
            let changeStatusAction = UIAlertAction(title: title, style: .default) {
                (alert: UIAlertAction!) -> Void in
                if self.protectors[index].protectingYou == true {
                    self.protectors[index].protectingYou = false
                    DatabaseManager.deactivateProtector(self.protectors[index]) {
                        (error) in
                        guard error == nil else{
                            print("Error in deactivating protector")
                            return
                        }
                    }
                }
                else {
                    self.protectors[index].protectingYou = true
                    DatabaseManager.addProtector(self.protectors[index]) {
                        (error) in
                        guard error == nil else {
                            print("Error in deactivating protector")
                            return
                        }
                    }
                }
            }
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) {
                (alert: UIAlertAction!) -> Void in
                AppSettings.mainUser!.removeProtector(self.protectors[index])
                self.protectors.remove(at: index)
                self.collectionView?.reloadData()
            }
            optionMenu.addAction(changeStatusAction)
            optionMenu.addAction(deleteAction)
        } else if segmentedControl.selectedSegmentIndex == 1 {
            let seeOnMapAction = UIAlertAction(title: "See on map", style: .default) {
                (alert: UIAlertAction!) -> Void in
                self.findUser(atIndex: index)
            }
            optionMenu.addAction(seeOnMapAction)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        }
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    func findUser(atIndex index: Int) {
        let protected = self.protected[index]
        let navigationController = tabBarController?.viewControllers?.first
        let mapViewController = navigationController?.childViewControllers[0] as! MapViewController
        mapViewController.centerInLocation(location: protected.lastLocation!)
        self.tabBarController?.selectedIndex = 0
    }
}
extension ProtectCollectionViewController: LockProtocol {
    func showLockScreen() {
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
        let vc = UIStoryboard(name:"Help", bundle:nil).instantiateViewController(withIdentifier: "LockScreen")
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true)
    }
    func getCurrentDate() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
}
extension ProtectCollectionViewController: ProtectedsDelegateProtocol {
    func protectedAdded(protected: Protected) {
        let reuseIndex = segmentedControl.selectedSegmentIndex
        if reuseIndex == 1 {
            self.reloadData()
        }
    }
    func protectorRemoved(protected: Protected) {
        let reuseIndex = segmentedControl.selectedSegmentIndex
        if reuseIndex == 1 {
            self.reloadData()
        }
    }
}
