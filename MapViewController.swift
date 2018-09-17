import UIKit
import MapKit
import CoreLocation
import GooglePlaces
import WatchConnectivity
class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    var location: CLLocation?
    var locationServices: LocationServices?
	var placeCalloutView: PlaceCalloutView?
    var displayInCenter: String = ""
    var selectedAnnotation : PlaceAnnotation?
    var showPlace: Int?
    var protectedsAnnotationArray : [ProtectedAnnotation] = []
	var launched: Bool = false
	var watchSessionManager: WatchSessionManager?
	private let session = WCSession.default
    @IBOutlet weak var timerButton: UIButton!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var currentLocationLabel: UILabel!
    @IBOutlet weak var anotherUserLocationLabel: UILabel!
    override func viewWillAppear(_ animated: Bool) {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGesture(gestureReconizer:)))
        longPressGestureRecognizer.delegate = self
        longPressGestureRecognizer.minimumPressDuration = 0.5
        map.addGestureRecognizer(longPressGestureRecognizer)
        if let userTimer = AppSettings.mainUser!.arrivalInformation?.timer {
            userTimer.delegate = self
            setTimerText(timeString: userTimer.timeString)
        } else {
            timerButton.isHidden = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.displayInCenter = ""
        self.timerButton.isHidden = true
        self.map.delegate = self
        self.locationServices = LocationServices()
        self.map.showsUserLocation = true
        self.map.showsCompass = false
		self.launched = false
		self.watchSessionManager = WatchSessionManager()
		self.watchSessionManager?.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
		DatabaseManager.addObserverToProtectedsETA() {
			(protectedId, ETA) in
			guard let arrivalInformation = ETA else {
				print("Error on adding observer to protecteds ETA")
				return
			}
			let pArray = AppSettings.mainUser?.protecteds
            let protected = AppSettings.mainUser?.getUser(byId: (protectedId)!, fromList: pArray!) as! Protected
			if arrivalInformation.expectedTimeOfArrival == 0 {
				if let arrInfo = protected.arrivalInformation {
					if let timerDelegate = arrInfo.timer.delegate {
						timerDelegate.dismissTimer()
					}
					protected.arrivalInformation = nil
				}
				protected.status = userStatus.safe
				let alertController = UIAlertController(title: "Alerta",
														message: "\(protected.name) chegou em segurança",
														preferredStyle: UIAlertControllerStyle.alert)
				alertController.addAction(UIAlertAction(title: "Ok",
														style: UIAlertActionStyle.cancel,
														handler: { action in
															AppSettings.mainUser!.arrived()
				}))
				self.present(alertController, animated: true, completion: nil)
				return
			}
			protected.arrivalInformation = arrivalInformation
			protected.arrivalInformation?.timer.start()
			protected.status = userStatus.arriving
		}
        DatabaseManager.addObserverToProtectedsHelpOccurrences() {
            (helpOccurrence, protected) in
            if helpOccurrence == nil {
				if protected == nil {
					print("Error on adding a observer to help occurrences.")
					return
				} else {
					protected?.status = userStatus.safe
					return
				}
            }
			protected?.status = userStatus.danger
			self.displayHelpOccurrence(helpOccurrence: helpOccurrence!, protected: protected!, showCallout: false)
			if !(self.launched) {
				let alertController = UIAlertController(title: "\(protected!.name.capitalized) asked for your help. Try to understand what's happening and help him.",
					message: nil,
					preferredStyle: UIAlertControllerStyle.alert)
				alertController.addAction(UIAlertAction(title: "Ok",
														style: UIAlertActionStyle.cancel,
														handler: { action in
				}))
				self.present(alertController, animated: true, completion: nil)
			}
        }
        self.addObservertoProtectedsLocations()
        AppSettings.mainUser!.protectedsDelegate = self
        for place in AppSettings.mainUser!.places {
			self.displayLocation(place: place, showCallout: false)
        }
        print("User places: \(AppSettings.mainUser!.places.count)")
		if !launched && locationServices?.authorizationStatus == CLAuthorizationStatus.authorizedWhenInUse {
			self.displayCurrentLocation()
			launched = true
		}
		let locked = LockServices.checkLockMode()
		if locked == true {
			let vc = UIStoryboard(name:"Help", bundle:nil).instantiateViewController(withIdentifier: "LockScreen")
            vc.modalTransitionStyle = .crossDissolve
			self.present(vc, animated: true)
		}
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.locationServices = nil
        if let userTimer = AppSettings.mainUser!.arrivalInformation?.timer {
            userTimer.delegate = nil
        }
        AppSettings.mainUser!.protectedsDelegate = nil
        self.removeObservertoProtectedsLocations()
    }
    @objc func longPressGesture(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == .began {
            let tap = gestureReconizer.location(in: map)
            let tapCoordinate = map.convert(tap, toCoordinateFrom: map)
            let mapCoordinate = Coordinate(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude)
            LocationServices.coordinateToPlaceInfo(coordinate: mapCoordinate) {
                (_place) in
                var place = Place(name: "", address: "", city: "", state: "", country: "", coordinate: mapCoordinate)
                if _place != nil {
                    place = _place!
                }
                self.displayLocation(newPlace: place, showCallout: true)
            }
            print("Long Press Gesture: \(mapCoordinate)")
        }
    }
    @IBAction func sendLocation(_ sender: Any) {
        if let location = AppSettings.mainUser!.lastLocation {
            DatabaseManager.updateLastLocation(location) {
                (error) in
                guard (error == nil) else {
                    print("Error on updating user's current location to DB.")
                    return
                }
            }
        }
    }
    @IBAction func zoomInUserLocation(_ sender: Any) {
        self.displayCurrentLocation()
    }
    @IBAction func searchButtonClicked(_ sender: UIBarButtonItem) {
        self.autocompleteSearch()
    }
    @IBAction func setTimer() {
        performSegue(withIdentifier: "SetDestinationTableViewController", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
            case "AddPlaceViewController":
                guard let locationInfo = self.selectedAnnotation?.locationInfo else {
                    print("Error on sending location information to AddPlaceViewController.")
                    return
                }
                let segueDestination = segue.destination as? AddPlaceTableViewController
                segueDestination?.locationInfo = locationInfo
                break
            case "SetDestinationTableViewController":
                guard let locationInfo = self.selectedAnnotation?.locationInfo else {
                    print("Error on sending location information to AddPlaceViewController.")
                    return
                }
                let segueDestination = segue.destination as! SetDestinationTableViewController
                segueDestination.locationInfo = locationInfo
                break
            case "TimerDetailsViewController":
                let segueDestination = segue.destination as! TimerDetailsViewController
                break
            default:
                break
        }
    }
}
extension MapViewController: LockProtocol {
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
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        if let annotation = annotation as? Annotation {
            let identifier = annotation.identifier
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                if let personAnnotation = annotation as? ProtectedAnnotation {
                    annotationView = PersonPinView(annotation: personAnnotation, reuseIdentifier: identifier)
                } else if let placeAnnotation = annotation as? PlaceAnnotation {
                    annotationView = PlacePinView(annotation: placeAnnotation, reuseIdentifier: identifier)
                    (annotationView as! PlacePinView).placeCalloutDelegate = self
                } else if let helpAnnotation = annotation as? HelpAnnotation {
                    annotationView = OccurrencePinView(annotation: helpAnnotation, reuseIdentifier: identifier)
                }
            }
            return annotationView
        }
        return nil
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let view = view as? PlacePinView {
            self.selectedAnnotation = (view.annotation as! PlaceAnnotation)
        }
    }
	func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
		if let placeAnnotation = view.annotation as? PlaceAnnotation {
			if placeAnnotation.identifier == AnnotationIdentifiers.newPlace {
				var placeAdded = false
				let placeCoordinate = Coordinate(latitude: placeAnnotation.coordinate.latitude, longitude: placeAnnotation.coordinate.longitude)
				for place in (AppSettings.mainUser?.places)! {
					if (placeCoordinate.latitude == place.coordinate.latitude) && (placeCoordinate.longitude == place.coordinate.longitude) {
						placeAdded = true
					}
				}
				if(placeAdded == false){
					view.removeFromSuperview()
					self.map.removeAnnotation(placeAnnotation)
				}
			}
			print(placeAnnotation.name)
			print(placeAnnotation.locationInfo?.name)
		}
	}
}
extension MapViewController: PlaceCalloutDelegate {
    func setDestination() {
        performSegue(withIdentifier: "SetDestinationTableViewController", sender: nil)
    }
    func addToPlaces() {
		print("add place")
        performSegue(withIdentifier: "AddPlaceViewController", sender: nil)
    }
}
extension MapViewController: LocationUpdateProtocol {
    func centerInLocation(location: Coordinate) {
        let location2D = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(location2D, span)
        map.setRegion(region, animated: true)
    }
    func displayCurrentLocation() {
        let myLoc2D = Coordinate(latitude: AppSettings.mainUser!.lastLocation!.latitude, longitude: AppSettings.mainUser!.lastLocation!.longitude)
        self.centerInLocation(location: myLoc2D)
    }
    func displayLocation(protected: Protected, showCallout: Bool) {
        self.removeAnnotationFrom(protected: protected)
        let protectedAnnotation = ProtectedAnnotation(protected: protected)
        self.map.addAnnotation(protectedAnnotation)
        protectedsAnnotationArray.append(protectedAnnotation)
    }
    func removeAnnotationFrom(protected: Protected) {
        for i in 0 ..< protectedsAnnotationArray.count {
            let protectedAnnotation = protectedsAnnotationArray[i]
            if protected.id == protectedAnnotation.protected.id {
                self.map.removeAnnotation(protectedAnnotation)
                self.protectedsAnnotationArray.remove(at: i)
                return
            }
        }
    }
    func displayLocation(place: Place, showCallout: Bool) {
        let someLoc2D = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        let locationInfo = LocationInfo(name: place.address, address: place.address, city: place.city, state: place.state, country: place.country, coordinate: place.coordinate)
        let placeAnnotation = PlaceAnnotation(locationInfo: locationInfo, name: place.name, identifier: AnnotationIdentifiers.myPlace, coordinate: someLoc2D)
        placeAnnotation.locationInfo = locationInfo
        self.map.addAnnotation(placeAnnotation)
        if showCallout {
            self.map.selectAnnotation(placeAnnotation, animated: true)
        }
    }
    func displayLocation(newPlace: Place, showCallout: Bool) {
        let someLoc2D = CLLocationCoordinate2D(latitude: newPlace.coordinate.latitude, longitude: newPlace.coordinate.longitude)
        let locationInfo = LocationInfo(name: newPlace.name, address: newPlace.address, city: newPlace.city, state: newPlace.state, country: newPlace.country, coordinate: newPlace.coordinate)
        let placeAnnotation = PlaceAnnotation(locationInfo: locationInfo, name: newPlace.name, identifier: AnnotationIdentifiers.newPlace, coordinate: someLoc2D)
        placeAnnotation.locationInfo = locationInfo
        self.map.addAnnotation(placeAnnotation)
        if showCallout {
            self.map.selectAnnotation(placeAnnotation, animated: true)
        }
    }
	func displayHelpOccurrence (helpOccurrence: HelpOccurrence, protected: Protected, showCallout: Bool) {
		LocationServices.coordinateToPlaceInfo(coordinate: helpOccurrence.coordinate) {
			(locationInfo) in
			guard let locationInfo = locationInfo else {
				print("Problem on fetching location information.")
				return
			}
			let helpAnnotation = HelpAnnotation(protected: protected, locationInfo: locationInfo, helpOccurrence: helpOccurrence)
			self.map.addAnnotation(helpAnnotation)
			if showCallout {
				self.map.selectAnnotation(helpAnnotation, animated: true)
			}
		}
	}
}
extension MapViewController: TimerObjectDelegate {
    func setTimerText(timeString: String) {
        if timerButton.isHidden == true {
            timerButton.isHidden = false
        }
        timerButton.setTitle(timeString, for: .normal)
    }
    func updateTimerText(timeString: String) {
        timerButton.setTitle(timeString, for: .normal)
    }
    func displayAlert() {
        let alertController = UIAlertController(title: "Have you arrived?",
                                                message: nil,
                                                preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Yes",
                                                style: UIAlertActionStyle.cancel,
                                                handler: { action in
                                                    AppSettings.mainUser!.arrived()
                                                }))
        alertController.addAction(UIAlertAction(title: "+5 min",
                                                style: UIAlertActionStyle.default,
                                                handler: { action in
													AppSettings.mainUser!.arrivalInformation!.timer.addTime(timeInSecs: 5*60)
                                                }))
        self.present(alertController, animated: true, completion: nil)
    }
    func dismissTimer() {
        timerButton.isHidden = true
		AppSettings.mainUser?.arrivalInformation?.expectedTimeOfArrival = 0
		DatabaseManager.addExpectedTimeOfArrival(arrivalInformation: (AppSettings.mainUser?.arrivalInformation)!, completionHandler: {
			(error) in
			if error != nil {
				print("Error on dismissing timer")
				return
			}
			AppSettings.mainUser?.status = userStatus.safe
			DatabaseManager.updateUserSatus() {
				(error) in
				if error != nil {
					print("Error on dismissing timer")
					return
				}
			}
		})
    }
}
extension MapViewController: GMSAutocompleteViewControllerDelegate {
    public func autocompleteSearch () {
        let placePickerController = GMSAutocompleteViewController()
        placePickerController.delegate = self
        let filter = GMSAutocompleteFilter()
        filter.country = "BR"
        placePickerController.autocompleteFilter = filter
        present(placePickerController, animated: true, completion: nil)
    }
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith gmsPlace: GMSPlace) {
        let coordinate = Coordinate(latitude: gmsPlace.coordinate.latitude, longitude: gmsPlace.coordinate.longitude)
        let GmsArray:NSArray = gmsPlace.addressComponents! as NSArray
       if(GmsArray.count == 3)
       {
        let GmsDict1:GMSAddressComponent = GmsArray[0] as! GMSAddressComponent
        let GmsDict2:GMSAddressComponent = GmsArray[1] as! GMSAddressComponent
        let GmsDict3:GMSAddressComponent = GmsArray[2] as! GMSAddressComponent
        let place = Place(name: gmsPlace.name, address: gmsPlace.formattedAddress!, city: GmsDict1.name, state: GmsDict2.name, country: GmsDict3.name, coordinate: coordinate)
        self.displayLocation(place: place, showCallout: true)
        self.centerInLocation(location: coordinate)
        }else
       {
        let GmsDict1:GMSAddressComponent = GmsArray[1] as! GMSAddressComponent
        let GmsDict2:GMSAddressComponent = GmsArray[2] as! GMSAddressComponent
        let GmsDict3:GMSAddressComponent = GmsArray[3] as! GMSAddressComponent
        let place = Place(name: gmsPlace.name, address: gmsPlace.formattedAddress!, city: GmsDict1.name, state: GmsDict2.name, country: GmsDict3.name, coordinate: coordinate)
        self.displayLocation(place: place, showCallout: true)
        self.centerInLocation(location: coordinate)
        }
        dismiss(animated: true, completion: nil)
    }
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
extension MapViewController: ProtectedsDelegateProtocol {
    func protectedAdded(protected: Protected) {
        self.addObserverToProtectedLocation(protected: protected)
    }
    func protectorRemoved(protected: Protected) {
        self.removeAnnotationFrom(protected: protected)
    }
}
extension MapViewController: ProtectedLocationDelegate {
    func setProtectedLocation(protected: Protected) {
        if (protected.allowedToFollow == true) || (protected.status == userStatus.danger) {
            self.displayLocation(protected: protected, showCallout: false)
        }
    }
    func updateProtectedLocation(protected: Protected) {
        if (protected.allowedToFollow == true) || (protected.status == userStatus.danger) {
            self.displayLocation(protected: protected, showCallout: false)
        }
    }
    func addObservertoProtectedsLocations() {
        for protected in AppSettings.mainUser!.protecteds {
            self.addObserverToProtectedLocation(protected: protected)
        }
    }
    func addObserverToProtectedLocation(protected: Protected) {
        protected.lastLocationDelegate = self
    }
    func removeObservertoProtectedsLocations() {
        for protected in AppSettings.mainUser!.protecteds {
            self.removeObserverToProtectedLocation(protected: protected)
        }
    }
    func removeObserverToProtectedLocation(protected: Protected) {
        protected.lastLocationDelegate = nil
    }
}
