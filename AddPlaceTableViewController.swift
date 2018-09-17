import UIKit
class AddPlaceTableViewController: UITableViewController {
    var locationInfo: LocationInfo!
    var placeAddress: String?
    var placeName: String?
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        guard let placeAddress = self.placeAddress else {
            print("Place address is nil.")
            return
        }
        guard let placeName = self.placeName else {
            print("Place name is nil.")
            return
        }
        LocationServices.addressToLocation(address: placeAddress) {
            (placeCoordinate) in
            let place = Place(name: placeName, address: placeAddress, city: self.locationInfo.city, state: self.locationInfo.state, country: self.locationInfo.country, coordinate: self.locationInfo.coordinate)
            AppSettings.mainUser?.addPlace(place)
            print("Place \(placeName) added to user's places.")
            self.navigationController?.popViewController(animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return 3
        }
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Name"
        } else {
            return "Address"
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "editableInfo", for: indexPath) as! EditInformationCell
            cell.editableInformation.placeholder = "Add a name to your place"
            cell.editableInformation.delegate = self
            cell.editableInformation.tag = 201
            return cell
        } else {
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "showableInfo", for: indexPath) as! ShowInformationCell
                cell.informationLabel.text = "\(locationInfo.address)"
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "editableInfo", for: indexPath) as! EditInformationCell
                cell.editableInformation.placeholder = "Add this place's number"
                cell.editableInformation.delegate = self
                cell.editableInformation.tag = 202
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "showableInfo", for: indexPath) as! ShowInformationCell
                cell.informationLabel.text = "\(locationInfo.city), \(locationInfo.state), \(locationInfo.country)"
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "showableInfo", for: indexPath) as! ShowInformationCell
                cell.informationLabel.text = ""
                return cell
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
extension AddPlaceTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return(true)
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 201 {
            self.placeName = "\(textField.text ?? "")"
        } else if textField.tag == 202 {
            self.placeAddress = "\(locationInfo.address), \(textField.text ?? "")"
        }
    }
}
