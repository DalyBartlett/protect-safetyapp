import Foundation
import FirebaseDatabase
import CoreLocation
class DatabaseManager {
    static var ref: DatabaseReference = Database.database().reference()
    static func checkConnection(completionHandler: @escaping (Bool) -> Void) {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observeSingleEvent(of: .value) {
            snapshot in
            if let connected = snapshot.value as? Bool, connected {
                print("Connected")
            } else {
                print("Not connected")
            }
        }
    }
    static func addUser(_ user: MainUser, completionHandler: @escaping (Error?) -> Void) {
        self.fetchUser(userID: user.id) {
            (userFetched) in
            if (userFetched != nil) {
                print("User was already included in the DB. Updating his name and email informations.")
            }
            let userRef = ref.child("users").child(user.id)
            let lastLocationDict: [String : AnyObject] = [
                "latitude": "" as AnyObject,
                "longitude": "" as AnyObject
            ]
            let userDict: [String : AnyObject] = [
                "name": user.name as AnyObject,
                "email": user.email as AnyObject,
				"status": user.status as AnyObject,
                "phoneNumber": user.phoneNumber as AnyObject,
                "lastLocation": lastLocationDict as AnyObject,
                "helpButtonOccurrences": "" as AnyObject,
                "places": "" as AnyObject,
                "protectors": "" as AnyObject,
                "protecteds": "" as AnyObject
            ]
            userRef.setValue(userDict) {
                (error, _) in
                guard (error == nil) else {
                    completionHandler(error)
                    return
                }
                completionHandler(nil)
            }
        }
    }
    static func updateUser(_ user: MainUser, completionHandler: @escaping (Error?) -> Void) {
        let userRef = ref.child("users/\(user.id)")
        let userDict: [AnyHashable: Any] = [
            "name": user.name,
            "email": user.email,
			"status": user.status,
            "phoneNumber": user.phoneNumber,
            "lastLocation/latitude": user.lastLocation!.latitude as Double,
            "lastLocation/longitude": user.lastLocation!.longitude as Double
        ]
        userRef.updateChildValues(userDict) {
            (error, _) in
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
    static func addProtector(_ protector: Protector, completionHandler: @escaping (Error?) -> Void) {
        let usersRef = ref.child("users")
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        usersRef.child(AppSettings.mainUser!.id).child("protectors").child(protector.id).setValue(true) {
            (error, _) in
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        usersRef.child(protector.id).child("protecteds").child(AppSettings.mainUser!.id).setValue(true) {
            (error, _) in
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            completionHandler(nil)
        }
    }
	static func deactivateProtector(_ protector: Protector, completionHandler: @escaping (Error?) -> Void) {
		let usersRef = ref.child("users")
        usersRef.child(AppSettings.mainUser!.id).child("protectors").child(protector.id).setValue(false) {
            (error, _) in
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
        usersRef.child(protector.id).child("protecteds").child(AppSettings.mainUser!.id).setValue(false) {
            (error, _) in
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
	}
    static func removeProtector(_ protector: Protector, completionHandler: @escaping (Bool) -> Void) {
        let mainUserRef = ref.child("users/\(protector.id)/protecteds/\(AppSettings.mainUser!.id)")
        let protectorRef = ref.child("users/\(AppSettings.mainUser!.id)/protectors/\(protector.id)")
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        mainUserRef.removeValue() {
            (error, _) in
            guard (error == nil) else {
                completionHandler(false)
                return
            }
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        protectorRef.removeValue() {
            (error, _) in
            guard (error == nil) else {
                completionHandler(false)
                return
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            completionHandler(true)
        }
    }
    static func addPlace(_ place: Place, completionHandler: @escaping (Error?) -> Void) {
        let placeRef = ref.child("users").child(AppSettings.mainUser!.id).child("places").child(place.name)
        let placeDict: [String : Any] = [
            "address": place.address,
            "city": place.city,
            "state": place.state,
            "country": place.country,
            "coordinates": [
                "latitude": place.coordinate.latitude,
                "longitude": place.coordinate.longitude
            ]
        ]
        placeRef.setValue(placeDict) {
            (error, _) in
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
    static func removePlace(_ place: Place, completionHandler: @escaping (Bool) -> Void) {
        let placeRef = ref.child("users/\(AppSettings.mainUser!.id)/places/\(place.name)")
        placeRef.removeValue {
            (error, _) in
            guard (error == nil) else {
                completionHandler(false)
                return
            }
            completionHandler(true)
        }
    }
    static func fetchUserBasicInfo(userDictionary: [String : AnyObject]) -> User? {
        guard let userID = userDictionary["id"] as? String else {
            print("Fetching user's id from DB returns nil.")
            return nil
        }
        guard let userName = userDictionary["name"] as? String else {
            print("Fetching user's name from DB returns nil.")
            return nil
        }
        guard let userEmail = userDictionary["email"] as? String else {
            print("Fetching user's email from DB returns nil.")
            return nil
        }
		guard let userStatus = userDictionary["status"] as? String else {
			print("Fetching user's status from DB returns nil.")
			return nil
		}
        guard let userPhoneNumber = userDictionary["phoneNumber"] as? String else {
            print("Fetching user's phone number from DB returns nil.")
            return nil
        }
        let user = User(id: userID, name: userName, email: userEmail, phoneNumber: userPhoneNumber, status: userStatus)
        print("User (\(user.name)) fetched successfully.")
		return user
    }
    static func fetchUserDetailedInfo(user: MainUser, userDictionary: [String : AnyObject], completionHandler: @escaping (Bool) -> Void) {
        let placesDict = userDictionary["places"] as? [String : AnyObject] ?? [:]
        guard let userPlaces = readPlaces(placesDict: placesDict) else {
            print("Fetching user's places from DB returns nil.")
            completionHandler(false)
            return
        }
        let protectorsDict = userDictionary["protectors"] as? [String : AnyObject] ?? [:]
        var userProtectors: [Protector] = []
        let dispatchGroup = DispatchGroup()
        for protectorDict in protectorsDict {
            let protectorID = protectorDict.key
			guard let protectorStatus = protectorDict.value as? Bool else {
				print("Fetching user's protectors' status (on/off) from DB returns nil.")
				completionHandler(false)
				return
			}
            dispatchGroup.enter()
            fetchProtector(protectorID: protectorID) {
                (protector) in
                guard let protector = protector else {
                    print("Error on fetching protector with id: \(protectorID).")
                    completionHandler(false)
                    return
                }
				protector.protectingYou = protectorStatus
                userProtectors.append(protector)
                dispatchGroup.leave()
            }
        }
        let protectedsDict = userDictionary["protecteds"] as? [String : AnyObject] ?? [:]
        var userProtecteds: [Protected] = []
        for protectedDict in protectedsDict {
            let protectedID = protectedDict.key
            guard let protectedStatus = protectedDict.value as? Bool else {
                print("Fetching user's protecteds' status (on/off) from DB returns nil.")
                completionHandler(false)
                return
            }
            dispatchGroup.enter()
            fetchProtected(protectedID: protectedID) {
                (protected) in
                guard let protected = protected else {
                    print("Error on fetching protector with id: \(protectedID).")
                    completionHandler(false)
                    return
                }
                protected.allowedToFollow = protectedStatus
                userProtecteds.append(protected)
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            user.places = userPlaces
            user.protectors = userProtectors
            user.protecteds = userProtecteds
            completionHandler(true)
        }
    }
    static func fetchUserPlaces(completionHandler: @escaping ([Place]?) -> Void) {
        let userRef = ref.child("users/\(String(describing: AppSettings.mainUser?.id))")
        userRef.observeSingleEvent(of: .value) {
            (userSnapshot) in
            guard var userDictionary = userSnapshot.value as? [String: AnyObject] else {
                print("User ID fetched returned a nil snapshot from DB.")
                completionHandler(nil)
                return
            }
            let placesDict = userDictionary["places"] as? [String : AnyObject] ?? [:]
            guard let userPlaces = readPlaces(placesDict: placesDict) else {
                print("Fetching user's places from DB returns nil.")
                completionHandler(nil)
                return
            }
            completionHandler(userPlaces)
        }
    }
    static func fetchUser(userID: String, completionHandler: @escaping (MainUser?) -> Void) {
        let userRef = ref.child("users/\(userID)")
        userRef.observeSingleEvent(of: .value) {
            (userSnapshot) in
            guard var userDictionary = userSnapshot.value as? [String: AnyObject] else {
                print("User ID fetched returned a nil snapshot from DB.")
                completionHandler(nil)
                return
            }
            userDictionary["id"] = userID as AnyObject
            guard let user = fetchUserBasicInfo(userDictionary: userDictionary) else {
                print("Error on fetching user's (\(userID)) basic profile information.")
                completionHandler(nil)
                return
            }
			let mainUser = MainUser(id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, status: user.status)
            fetchUserDetailedInfo(user: mainUser, userDictionary: userDictionary) {
                (success) in
                guard (success == true) else {
                    print("Error on fetching user's detailed profile information.")
                    completionHandler(nil)
                    return
                }
                completionHandler(mainUser)
            }
        }
    }
    static func fetchProtector(protectorID: String, completionHandler: @escaping (Protector?) -> Void) {
        let protectorRef = ref.child("users/\(protectorID)")
        protectorRef.observeSingleEvent(of: .value) {
            (protectorSnapshot) in
            guard var protectorDictionary = protectorSnapshot.value as? [String: AnyObject] else {
                print("User ID fetched returned a nil snapshot from DB.")
                completionHandler(nil)
                return
            }
            protectorDictionary["id"] = protectorID as AnyObject
            guard let user = fetchUserBasicInfo(userDictionary: protectorDictionary) else {
                print("Error on fetching user's (id: \(protectorID)) basic profile information.")
                completionHandler(nil)
                return
            }
			let protector = Protector(id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, status: userStatus.safe)
            completionHandler(protector)
        }
    }
    static func fetchProtector(protectorName: String, completionHandler: @escaping (Protector?) -> Void) {
        let usersRef = ref.child("users")
        usersRef.queryOrdered(byChild: "name").queryEqual(toValue: protectorName).observeSingleEvent(of: .value) {
            (protectorsSnapshot) in
            if let protectorsSnapList = protectorsSnapshot.children.allObjects as? [DataSnapshot] {
                if (protectorsSnapList.count == 0) {
                    print("No user with this name found on DB.")
                    completionHandler(nil)
                    return
                } else if (protectorsSnapList.count != 1) {
                    print("Found more than one user with this name on DB.")
                    completionHandler(nil)
                    return
                }
                let protectorSnap = protectorsSnapList[0]
                guard var protectedDictionary = protectorSnap.value as? [String: AnyObject] else {
                    print("User ID fetched returned a nil snapshot from DB.")
                    completionHandler(nil)
                    return
                }
                protectedDictionary["id"] = protectorSnap.key as AnyObject
                guard let user = fetchUserBasicInfo(userDictionary: protectedDictionary) else {
                    print("Error on fetching user's (\(protectorName)) basic profile information.")
                    completionHandler(nil)
                    return
                }
				let protector = Protector(id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, status: userStatus.safe)
                completionHandler(protector)
            }
        }
    }
    static func fetchProtected(protectedID: String, completionHandler: @escaping (Protected?) -> Void) {
        let protectedRef = ref.child("users/\(protectedID)")
        protectedRef.observeSingleEvent(of: .value) {
            (protectedSnapshot) in
            guard var protectedDictionary = protectedSnapshot.value as? [String : AnyObject] else {
                print("User ID fetched returned a nil snapshot from DB.")
                return
            }
            protectedDictionary["id"] = protectedSnapshot.key as AnyObject
            guard let user = fetchUserBasicInfo(userDictionary: protectedDictionary) else {
                print("Error on fetching user's (\(protectedID)) basic profile information.")
                completionHandler(nil)
                return
            }
			let protected = Protected(id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, status: userStatus.safe)
            guard let lastLocationDict = protectedDictionary["lastLocation"] as? [String : Double] else {
                print("User ID fetched returned last location nil from DB.")
                completionHandler(nil)
                return
            }
            guard let protectedLastLocation = fetchLastLocation(lastLocationDict: lastLocationDict) else {
                print("Error on fetching user's (\(protectedID)) last location.")
                completionHandler(nil)
                return
            }
            protected.lastLocation = protectedLastLocation
            completionHandler(protected)
        }
    }
    static func fetchProtected(protectedName: String, completionHandler: @escaping (Protected?) -> Void) {
        let usersRef = ref.child("users")
        usersRef.queryEqual(toValue: protectedName, childKey: "name").observeSingleEvent(of: .value) {
            (protectedsSnapshot) in
            if let protectedSnapList = protectedsSnapshot.children.allObjects as? [DataSnapshot] {
                if (protectedSnapList.count == 0) {
                    print("No user with this name found on DB.")
                    completionHandler(nil)
                    return
                } else if (protectedSnapList.count != 1) {
                    print("Found more than one user with this name on DB.")
                    completionHandler(nil)
                    return
                }
                let protectedSnap = protectedSnapList[0]
                guard var protectedDict = protectedSnap.value as? [String : AnyObject] else {
                    print("User ID fetched returned a nil snapshot from DB.")
                    return
                }
                protectedDict["id"] = protectedSnap.key as AnyObject
                guard let protected = fetchUserBasicInfo(userDictionary: protectedDict) as? Protected else {
                    print("Error on fetching user's (\(protectedName)) basic profile information.")
                    completionHandler(nil)
                    return
                }
                guard let lastLocationDict = protectedDict["lastLocation"] as? [String : Double] else {
                    print("User ID fetched returned last location nil from DB.")
                    completionHandler(nil)
                    return
                }
                if let protectedLastLocation = fetchLastLocation(lastLocationDict: lastLocationDict) {
                    protected.lastLocation = protectedLastLocation
                } else {
                    print("Error on fetching user's (\(protectedName)) last location.")
                }
                completionHandler(protected)
            }
        }
    }
    static func readPlaces(placesDict: [String : AnyObject]) -> [Place]? {
        var userPlaces: [Place] = []
        for placeDict in placesDict {
            let placeName: String = placeDict.key
            guard let placeAddress = placeDict.value["address"] as? String else {
                print("Fetching user's places from DB returns a place with address nil.")
                return nil
            }
            guard let placeCity = placeDict.value["city"] as? String else {
                print("Fetching user's places from DB returns a place with city nil.")
                return nil
            }
            guard let placeState = placeDict.value["state"] as? String else {
                print("Fetching user's places from DB returns a place with state nil.")
                return nil
            }
            guard let placeCountry = placeDict.value["country"] as? String else {
                print("Fetching user's places from DB returns a place with country nil.")
                return nil
            }
            guard let placeCoordinatesDict = placeDict.value["coordinates"] as? [String : AnyObject] else {
                print("Fetching user's places from DB returns a place with coordinates nil.")
                return nil
            }
            guard let placeLatitude = placeCoordinatesDict["latitude"] as? Double else {
                print("Fetching user's places from DB returns a place with latitude nil.")
                return nil
            }
            guard let placeLongitude = placeCoordinatesDict["longitude"] as? Double else {
                print("Fetching user's places from DB returns a place with longitude nil.")
                return nil
            }
            let placeCoordinates = Coordinate(latitude: placeLatitude, longitude: placeLongitude)
            let place = Place(name: placeName, address: placeAddress, city: placeCity, state: placeState, country: placeCountry, coordinate: placeCoordinates)
            userPlaces.append(place)
        }
        return userPlaces
    }
    static func fetchLastLocation(lastLocationDict: [String : Double]) -> Coordinate? {
        guard let latitude = lastLocationDict["latitude"] else {
            print("Error on fetching latitude from given last location dictionary.")
            return nil
        }
        guard let longitude = lastLocationDict["longitude"] else {
            print("Error on fetching longitude from given last location dictionary.")
            return nil
        }
        return Coordinate(latitude: latitude, longitude: longitude)
    }
	static func addHelpOccurrence(helpOccurrence: HelpOccurrence, completionHandler: @escaping (Error?) -> Void){
		let helpRef = ref.child("users").child(AppSettings.mainUser!.id).child("helpButtonOccurrences")
		let helpDict: [String : Any] = [
			"\(helpOccurrence.date)": [
				"latitude": helpOccurrence.coordinate.latitude,
				"longitude": helpOccurrence.coordinate.longitude
				]
		]
		helpRef.setValue(helpDict) {
			(error, _) in
			guard (error == nil) else {
				completionHandler(error)
				return
			}
			completionHandler(nil)
		}
	}
	static func removeHelpOccurrence(date: String, completionHandler: @escaping (Error?) -> Void) {
		let helpRef = ref.child("users").child(AppSettings.mainUser!.id).child("helpButtonOccurrences")
		let helpDict: [String: Any] = [
			date : ""
		]
		helpRef.setValue(helpDict) {
			(error, _) in
			guard (error == nil) else {
				completionHandler(error)
				return
			}
			completionHandler(nil)
		}
	}
	static func addObserverToProtectedsHelpOccurrences(completionHandler: @escaping (HelpOccurrence?, Protected?) -> Void){
		for protected in AppSettings.mainUser!.protecteds {
			let protectedHelpButtonOccurrencesRef = ref.child("users/\(protected.id)/helpButtonOccurrences")
			protectedHelpButtonOccurrencesRef.observe(.childAdded) {
				(helpButtonOccurrencesSnap) in
				guard let helpOccurrenceDict = helpButtonOccurrencesSnap.value as? [String:Double] else {
					print("Add observer returned help occurrencces nil snapshot from DB.")
					completionHandler(nil, protected)
					return
				}
				let date = helpButtonOccurrencesSnap.key as String
				let coordinate = Coordinate(latitude: helpOccurrenceDict["latitude"]!, longitude: helpOccurrenceDict["longitude"]!)
				let helpOccurrence = HelpOccurrence(date: date, coordinate: coordinate)
				completionHandler(helpOccurrence, protected)
			}
		}
	}
	static func addObserverToProtectedsETA(completionHandler: @escaping (String?, ArrivalInformation?) -> Void){
		for protected in (AppSettings.mainUser?.protecteds)! {
			let ETARef = ref.child("users").child(protected.id).child("ETA")
			ETARef.observe(.childChanged, with: {
				(ETASnap) in
				ETARef.observe(.value, with: {
					(ETASnap) in
					guard let ETADict = ETASnap.value as? [String : Any] else {
						print("Add observer to ETA returned nil snapshot from DB")
						return
					}
					guard let protectorsDict = ETADict["protectors"] as? [String:Any] else {
						print("Error on fetching protectorsDict from given ETA dictionary.")
						return
					}
					var protectorsId: [String] = []
					var protectorIsOn: Bool = false
					for i in Array(protectorsDict.keys) {
						if i == AppSettings.mainUser?.id {
							protectorIsOn = true
						}
						protectorsId.append(i)
					}
					if protectorIsOn == false {
						completionHandler(nil, nil)
						return
					}
					guard let date = ETADict["date"] as? String else {
						print("Error on fetching date from given ETA dictionary.")
						return
					}
					guard let destination = ETADict["destination"] as? String else {
						print("Error on fetching destination from given ETA dictionary.")
						return
					}
					guard let timeOfArrival = ETADict["time of arrival"] as? String else {
						print("Error on fetching time of arrival from given ETA dictionary.")
						return
					}
                   let locationInfo = LocationInfo(name: "Destination of ////////insert id/////////", address: destination, city: "", state: "", country: "", coordinate: protected.lastLocation!)
					let timeOfArrivalInt = Int(Double(timeOfArrival)!)
					let timer = TimerObject(seconds: timeOfArrivalInt,
											destination: CLLocation(latitude: 37.2, longitude: 22.9),
											delegate: nil)
					let arrivalInformation = ArrivalInformation(date: date, destination: locationInfo, startPoint: nil, expectedTimeOfArrival: timeOfArrivalInt, protectorsId: protectorsId, timer: timer)
					completionHandler(protected.id, arrivalInformation)
				})
			})
		}
	}
    static func addObserverToProtectedsLocations(completionHandler: @escaping (Protected?) -> Void) {
        print("Number of protecteds: \(AppSettings.mainUser!.protecteds.count)")
        for protected in AppSettings.mainUser!.protecteds {
            let protectedLastLocationRef = ref.child("users/\(protected.id)/lastLocation")
            protectedLastLocationRef.observe(.value) {
                (lastLocationSnap) in
                guard let lastLocationDict = lastLocationSnap.value as? [String : Double] else {
                    print("User fetched returned last location nil snapshot from DB.")
                    completionHandler(nil)
                    return
                }
                let protectedLocation = fetchLastLocation(lastLocationDict: lastLocationDict)
                protected.lastLocation = protectedLocation
                completionHandler(protected)
                print("Protected [\(protected.name)] new location: \(protected.lastLocation!.latitude), \(protected.lastLocation!.longitude)")
            }
        }
    }
    static func removeObserverFromProtectedsLocations() {
        for protected in AppSettings.mainUser!.protecteds {
            let protectedLastLocationRef = ref.child("users/\(protected.id)/lastLocation")
            protectedLastLocationRef.removeAllObservers()
        }
    }
    static func updateLastLocation(_ location: Coordinate, completionHandler: @escaping (Error?) -> Void) {
        let lastLocationRef = ref.child("users/\(AppSettings.mainUser!.id)/lastLocation")
        let lastLocationDict = [
            "latitude": AppSettings.mainUser!.lastLocation?.latitude,
            "longitude": AppSettings.mainUser!.lastLocation?.longitude
        ]
        lastLocationRef.setValue(lastLocationDict) {
            (error, _) in
            guard (error == nil) else {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }
    static func getLastLocation(user: User, completionHandler: @escaping (Coordinate?) -> Void) {
        let lastLocationRef = ref.child(user.id).child("lastLocation")
        lastLocationRef.observeSingleEvent(of: .value) {
            (snapshot) in
            let latitude = snapshot.childSnapshot(forPath: "latitude").value! as! CLLocationDegrees
            let longitude = snapshot.childSnapshot(forPath: "longitude").value! as! CLLocationDegrees
            let userLocation = Coordinate(latitude: latitude, longitude: longitude)
            completionHandler(userLocation)
        }
    }
	static func addExpectedTimeOfArrival (arrivalInformation: ArrivalInformation, completionHandler: @escaping (Error?) -> Void) {
		let userRef = ref.child("users/\(AppSettings.mainUser!.id)/ETA")
		var protectorsDict : [String : Any] = [:]
		for protector in arrivalInformation.protectorsId {
			protectorsDict[protector] = "true"
		}
		let arrivalDict = [
			"date": arrivalInformation.date,
			"destination": arrivalInformation.destination?.address,
			"time of arrival": String(arrivalInformation.expectedTimeOfArrival),
			"protectors": protectorsDict
			] as [String : Any]
		userRef.setValue(arrivalDict){
			(error, _) in
			guard (error == nil) else {
				completionHandler(error)
				return
			}
			completionHandler(nil)
		}
	}
    static func addObserverToUserProtecteds() {
        return
        let userProtectedsRef = self.ref.child("users/\(AppSettings.mainUser!.id)/protecteds")
        userProtectedsRef.observe(.childAdded) {
            (snapshot) in
            let protectedID = snapshot.key as String
            guard let protectedValue = snapshot.value as? Bool else {
                print("--> Warning: Protected value returned non-boolean value from DB.")
                return
            }
            if protectedValue == true {
                AppSettings.mainUser!.addProtected(protectedID: protectedID)
            }
        }
        userProtectedsRef.observe(.childRemoved) {
            (snapshot) in
            let protectorID = snapshot.key as String
            AppSettings.mainUser!.removeProtected(protectedID: protectorID)
        }
    }
    static func addObserverToProtectedsStatus(completionHandler: @escaping (String?, String?) -> Void){
		for protected in AppSettings.mainUser!.protecteds {
			let protectedStatusRef = ref.child("users/\(protected.id)/status")
			protectedStatusRef.observe(.value) {
				(statusSnap) in
				guard let status = statusSnap.value as? String else {
					print("User fetched returned status nil snapshot from DB.")
					completionHandler(nil, nil)
					return
				}
				completionHandler(status, protected.id)
			}
		}
	}
	static func updateUserSatus(completionHandler: @escaping (Error?) -> Void){
		let statusRef = ref.child("users/\(AppSettings.mainUser!.id)/status")
		statusRef.setValue(AppSettings.mainUser?.status) {
			(error, _) in
			guard (error == nil) else {
				completionHandler(error)
				return
			}
			completionHandler(nil)
		}
	}
}
