import UIKit
import MapKit
import Nuke
protocol DestinationArrivalTimeDataSource: NSObjectProtocol {
    func getDestinationTime()->TimeInterval
}
class SetDestinationTableViewController: UITableViewController {
    var locationInfo: LocationInfo!
    var sections = ["Endereço","Tempo Esperado","Protetores"]
    var timerValue: TimeInterval!
    weak var destinationTimeDataSource: DestinationArrivalTimeDataSource?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberofrows = 0
        if section == 0{
            numberofrows = 1;
        }else if section == 1{
            numberofrows = 1;
        }else if section == 2{
            numberofrows = (AppSettings.mainUser?.protectors.count)!
        }
        return numberofrows
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let protectors = AppSettings.mainUser?.protectors
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "destinationcell", for: indexPath) as! DestinationTableViewCell
            cell.address.text = locationInfo.name
            cell.city.text = "\(locationInfo.city), \(locationInfo.state), \(locationInfo.country)"
            return cell
        }else if indexPath.section == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "timercell", for: indexPath) as! TimerCellTableViewCell
            cell.timer.countDownDuration = TimeInterval(0.0)
            self.timerValue = cell.timer.countDownDuration
            self.destinationTimeDataSource = cell
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "protectorcell", for: indexPath) as! ProtectorCellTableViewCell
            cell.protectorPic.layer.cornerRadius = cell.protectorPic.frame.height/2
            cell.protectorPic.image = UIImage(named: "collectionview_placeholder_image")
            Manager.shared.loadImage(with: protectors![indexPath.row].profilePictureURL, into: cell.protectorPic)
            cell.protectorPic.clipsToBounds = true
            cell.protectorName.text = protectors![indexPath.row].name
            cell.protectorId = protectors![indexPath.row].id
            return cell
        }
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 131
        } else {
            return 44
        }
	}
	func getCurrentDate() -> String {
		let date = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd/MM/yyyy   HH:mm"
		let dateString = dateFormatter.string(from: date)
		return dateString
	}
    @IBAction func doneButtonAction(_ sender: UIBarButtonItem) {
        var id = [String]()
        let section = 2
        let rows = tableView.numberOfRows(inSection: section)
        let etaValue = destinationTimeDataSource?.getDestinationTime() ?? 0
        for i in 0..<rows {
            let cell = tableView.cellForRow(at: IndexPath(row: i, section: section)) as! ProtectorCellTableViewCell
            if cell.protectorOnOff.isOn {
                id.append(cell.protectorId)
            }
        }
		guard let date = self.getCurrentDate() as? String else {
			print("Error in getting the current date")
			return
		}
        let timer = TimerObject(seconds: Int(etaValue),
                                destination: CLLocation(latitude: 37.2, longitude: 22.9),
                                delegate: nil)
        let arrivalInformation = ArrivalInformation(date: date, destination: self.locationInfo, startPoint: (AppSettings.mainUser?.lastLocation)!, expectedTimeOfArrival: Int(etaValue), protectorsId: id, timer: timer)
        AppSettings.mainUser!.arrivalInformation = arrivalInformation
        AppSettings.mainUser!.arrivalInformation?.timer.start()
		DatabaseManager.addExpectedTimeOfArrival(arrivalInformation: arrivalInformation){
			(error) in
			guard (error == nil) else {
				print("Error on adding new arrival time on DB.")
				return
			}
		}
		AppSettings.mainUser?.status = userStatus.arriving
		DatabaseManager.updateUserSatus() {
			(error) in
			if error != nil {
				print("Error on dismissing timer")
				return
			}
		}
        self.navigationController?.popViewController(animated: true)
    }
}
