import UIKit
class PlacesTableViewController: UITableViewController {
    var places: [Place] = []
	var watchSessionManager: WatchSessionManager?
    override func viewDidLoad() {
        super.viewDidLoad()
		self.watchSessionManager = WatchSessionManager()
		self.watchSessionManager?.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        loadPlaces()
        self.tableView.reloadData()
        print("User places: \(self.places.count)")
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.places.count
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            AppSettings.mainUser!.removePlace(places[indexPath.row])
            self.places.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! PlaceCell
        cell.placePin.image = UIImage(named:"cell_others")
        cell.placeLabel.text = self.places[indexPath.row].name
        cell.placeAddress.text = self.places[indexPath.row].address
        return cell
    }
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let navigationController = tabBarController?.viewControllers?.first
		let mapViewController = navigationController?.childViewControllers[0] as! MapViewController
		mapViewController.centerInLocation(location: places[indexPath.row].coordinate)
		self.tabBarController?.selectedIndex = 0
	}
    func loadPlaces() {
        if let userPlaces = AppSettings.mainUser?.places {
            self.places = userPlaces
        }
    }
}
extension PlacesTableViewController: LockProtocol {
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
