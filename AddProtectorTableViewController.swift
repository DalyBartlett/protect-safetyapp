import UIKit
import FirebaseDatabase
class AddProtectorTableViewController: UITableViewController {
	let searchController = UISearchController(searchResultsController: nil)
	@IBOutlet var addProtectorTableView: UITableView!
	var usersArray = [String]()
	var filteredUsers = [String]()
	var ref = Database.database().reference()
	override func viewDidLoad() {
        super.viewDidLoad()
		searchController.searchResultsUpdater = self
		searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false;
        searchController.searchBar.searchBarStyle = UISearchBarStyle.minimal
        searchController.searchBar.tintColor = UIApplication.shared.keyWindow?.tintColor
		definesPresentationContext = true
		tableView.tableHeaderView = searchController.searchBar
		ref.child("users").queryOrdered(byChild: "name").observe(.childAdded, with: {
			(snapshot) in
			let userName = snapshot.childSnapshot(forPath: "name").value as! String
			if userName != AppSettings.mainUser?.name {
				self.usersArray.append(userName)
				if self.searchController.isActive && self.searchController.searchBar.text != ""{
					self.addProtectorTableView.insertRows(at: [IndexPath.init(row: self.usersArray.count-1, section: 0)], with: UITableViewRowAnimation.automatic)
				}
			}
		}, withCancel: {
			(error) in
			print("Error in query users by name")
		})
    }
	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	func filteredContent(searchText: String){
		self.filteredUsers = self.usersArray.filter({
			(user) in
			return (user.lowercased().contains(searchText.lowercased()))
		})
		addProtectorTableView.reloadData()
	}
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if searchController.isActive && searchController.searchBar.text != "" {
			return filteredUsers.count
		}
		return 0
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addProtectorCell", for: indexPath)
		var user: String?
		if searchController.isActive && searchController.searchBar.text != "" {
			user = filteredUsers[indexPath.row]
			cell.textLabel?.text = user
		}
        return cell
    }
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		var protectorName: String?
		if searchController.isActive && searchController.searchBar.text != "" {
			protectorName = filteredUsers[indexPath.row]
		} else {
			protectorName = self.usersArray[indexPath.row]
		}
		DatabaseManager.fetchProtector(protectorName: protectorName!) {
			(protector) in
			if (protector == nil) {
				print("Error on fetching protector's information.")
				return
			}
			if let protector = protector{
				if !(AppSettings.mainUser?.protectors.contains(where: {$0.id == protector.id}))! {
					DatabaseManager.addProtector(protector) {
						(error) in
						guard error == nil else {
							print("Error on adding protector to user's database object.")
							return
						}
						AppSettings.mainUser?.protectors.append(protector)
						self.navigationController?.popViewController(animated: true)
					}
				} else {
					let alertController = UIAlertController(title: "Escolha outra pessoa.",
						message: "Essa pessoa já é seu protetor.",
						preferredStyle: UIAlertControllerStyle.alert)
					alertController.addAction(UIAlertAction(title: "Ok",
															style: UIAlertActionStyle.cancel,
															handler: { action in
					}))
					self.present(alertController, animated: true, completion: nil)
				}
			}
		}
	}
}
extension AddProtectorTableViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		filteredContent(searchText: self.searchController.searchBar.text!)
	}
}
