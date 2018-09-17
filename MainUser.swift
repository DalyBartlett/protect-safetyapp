import Foundation
protocol ProtectedsDelegateProtocol {
    func protectedAdded(protected: Protected)
    func protectorRemoved(protected: Protected)
}
class MainUser: User {
    var lastLocation: Coordinate?
    var places: [Place] = []
    var protectors: [Protector] = []
    var protecteds: [Protected] = []
    var arrivalInformation: ArrivalInformation?
    var protectedsDelegate: ProtectedsDelegateProtocol?
    private var _updateMapContinuously: Bool = false
    func updateLastLocation(_ coordinate: Coordinate) {
        DatabaseManager.updateLastLocation(coordinate) {
            (error) in
            guard (error == nil) else {
                print("Error on updating current location to database.")
                return
            }
            self.lastLocation = coordinate
        }
    }
    func addPlace(_ place: Place) {
        DatabaseManager.addPlace(place) {
            (error) in
            guard (error == nil) else {
                print("Error on adding place to database.")
                return
            }
            self.places.append(place)
        }
    }
    func removePlace(_ place: Place) {
        DatabaseManager.removePlace(place) {
            (success) in
            guard success else {
                print("ERROR: Could not remove place \(place.name) from user's DB.")
                return
            }
            for i in 0..<self.places.count {
                if self.places[i].name == place.name {
                    self.places.remove(at: i)
                    print("Place \(place.name) removed successfully.")
                    return
                }
            }
        }
    }
    func fetchPlaces(completionHandler: @escaping (Bool) -> Void) {
        DatabaseManager.fetchUserPlaces() {
            (userPlaces) in
            guard let userPlaces = userPlaces else {
                print("Fetching user places returned nil.")
                completionHandler(false)
                return
            }
            print("User Places[] fetched successfully.")
            self.places = userPlaces
            completionHandler(true)
        }
    }
    func addProtector(_ protector: Protector) {
        for p in self.protectors {
            if p.id == protector.id {
                print("User \(protector.name) has already been added as user's protectors.")
                return
            }
        }
        DatabaseManager.addProtector(protector) {
            (error) in
            guard (error == nil) else {
                print("Error on adding protector to database.")
                return
            }
            print("Protector \(protector.name) added to user's database.")
            self.protectors.append(protector)
        }
    }
    func removeProtector(_ protector: Protector) {
        DatabaseManager.removeProtector(protector) {
            (success) in
            guard success else {
                print("ERROR: Could not remove protector \(protector.name) from user's DB.")
                return
            }
            for i in 0..<self.protectors.count {
                if self.protectors[i].id == protector.id {
                    print("Protector \(self.protectors[i].name) removed successfully.")
                    self.protectors.remove(at: i)
                    return
                }
            }
        }
    }
    func addProtected(protectedID: String) {
        for protected in self.protecteds {
            if protected.id == protectedID {
                print("User with id (\(protectedID)) has already been added as user's protecteds.")
                return
            }
        }
        DatabaseManager.fetchProtected(protectedID: protectedID) {
            (protected) in
            guard let protected = protected else {
                print("Error on fetching protector with id: \(protectedID).")
                return
            }
            self.protecteds.append(protected)
            if let protectedsDelegate = self.protectedsDelegate {
                protectedsDelegate.protectedAdded(protected: protected)
            }
            print("Protected \(protected.name) added to user's protecteds.")
        }
    }
    func removeProtected(protectedID: String) {
        for i in 0 ..< protecteds.count {
            if protecteds[i].id == protectedID {
                print("Protected \(protecteds[i].name) has removed user \(AppSettings.mainUser!.name) as protector.")
                let deletedProtected = protecteds[i]
                protecteds.remove(at: i)
                if self.protectedsDelegate != nil {
                    self.protectedsDelegate?.protectorRemoved(protected: deletedProtected)
                }
            }
        }
    }
    func getUser(byId id: String, fromList list: [User]) -> User? {
        for p in list {
            if p.id == id {
                print ("User with ID [\(id)] found with name \(p.name)")
                return p
            }
        }
        print ("User with ID (\(id)) not found on list")
        return nil
    }
    func arrived() {
        if let timerDelegate = self.arrivalInformation?.timer.delegate {
            timerDelegate.dismissTimer()
        }
        self.arrivalInformation = nil
    }
}
