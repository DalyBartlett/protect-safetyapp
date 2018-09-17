import UIKit
class PhoneTableViewController: UITableViewController {
    let names = ["Polícia Militar", "Samu", "Bombeiros", "Guarda Municipal", "Defesa Civil", "Disque Denúncia"]
    let numbers = ["190", "192", "193", "153", "199", "181"]
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.names.count
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let  phoneAlertController = UIAlertController(title: "\(self.numbers[indexPath.row])", message: "\(self.names[indexPath.row])", preferredStyle: UIAlertControllerStyle.alert)
        phoneAlertController.addAction(UIAlertAction(title: "Ligar", style: UIAlertActionStyle.default, handler: {action in
            let phone  = URL(string: "tel://\(self.numbers[indexPath.row])")
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(phone!)
            } else {
            }
        }))
        phoneAlertController.addAction(UIAlertAction(title: "Cancelar", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(phoneAlertController, animated: true, completion: nil)
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "phoneCell", for: indexPath)
        cell.textLabel?.text = self.names[indexPath.row]
        cell.detailTextLabel?.text = self.numbers[indexPath.row]
        return cell
    }
}
