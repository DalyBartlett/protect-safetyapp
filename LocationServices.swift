import Foundation
import CoreLocation
protocol LocationUpdateProtocol {
	func centerInLocation(location: Coordinate)
    func displayCurrentLocation()
}
class LocationServices: NSObject {
    var manager = CLLocationManager()
    var geocoder = CLGeocoder()
	let ratio: Double = 30
	public var authorizationStatus: CLAuthorizationStatus?
    override init() {
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
				authorizationStatus = CLAuthorizationStatus.notDetermined
                self.manager.requestWhenInUseAuthorization()
                break
            case .restricted, .denied:
				authorizationStatus = CLAuthorizationStatus.denied
                print("Error: permission denied or restricted")
                self.manager.stopUpdatingLocation()
                break
            case .authorizedWhenInUse, .authorizedAlways:
				authorizationStatus = CLAuthorizationStatus.authorizedWhenInUse
                self.manager.startUpdatingLocation()
                break
        }
    }
}
extension LocationServices: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard locations.count > 0 else {
            print("Current location is nil.")
            return
        }
        let lastCoordinate = locations[0].coordinate
        let userLocation = Coordinate(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        AppSettings.mainUser!.lastLocation = userLocation
        print("Updating main user's location: \(userLocation.latitude), \(userLocation.longitude)")
        DatabaseManager.updateLastLocation(userLocation) {
            (error) in
            guard (error == nil) else {
                print("Error on updating user's last location on DB.")
                return
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == .authorizedAlways || status == .authorizedWhenInUse) {
            self.manager.startUpdatingLocation()
        } else if (status == .denied || status == .restricted) {
            self.manager.stopUpdatingLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
extension LocationServices {
    static func addressToLocation(address: String, completionHandler: @escaping (Coordinate?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) {
            (_placemarks, error) in
            guard (error == nil) else {
                print("Error on finding coordinate to given address.")
                completionHandler(nil)
                return
            }
            let placemarks = _placemarks! as [CLPlacemark]
            guard placemarks.count > 0 else {
                print("Problem receiving data from geocoder.")
                completionHandler(nil)
                return
            }
            let placemark: CLPlacemark = placemarks[0]
            guard let coord = placemark.location?.coordinate else {
                print("Problem on getting coordinate from placemark location.")
                completionHandler(nil)
                return
            }
            let coordinates = Coordinate(latitude: coord.latitude, longitude: coord.longitude)
            completionHandler(coordinates)
        }
    }
    static func coordinateToPlaceInfo(coordinate: Coordinate, completionHandler: @escaping (Place?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) {
            (_placemarks, error) in
            guard error == nil else {
                print("Error on reversing given coordinate to address.")
                completionHandler(nil)
                return
            }
            let placemarks = _placemarks! as [CLPlacemark]
            guard placemarks.count > 0 else {
                print("Problem receiving data from geocoder.")
                completionHandler(nil)
                return
            }
            let placemark: CLPlacemark = placemarks[0]
            guard let placeName = placemark.name else {
                print("Problem receiving address from geocoder.")
                completionHandler(nil)
                return
            }
            guard let placeAddress = placemark.thoroughfare else {
                print("Problem receiving address from geocoder.")
                completionHandler(nil)
                return
            }
            guard let placeCity = placemark.locality else {
                print("Problem receiving city from geocoder.")
                completionHandler(nil)
                return
            }
            guard let placeState = placemark.administrativeArea else {
                print("Problem receiving state from geocoder.")
                completionHandler(nil)
                return
            }
            guard let placeCountry = placemark.country else {
                print("Problem receiving country from geocoder.")
                completionHandler(nil)
                return
            }
            let placeInfo = Place(name: placeName, address: placeAddress, city: placeCity, state: placeState, country: placeCountry, coordinate: coordinate)
            completionHandler(placeInfo)
        }
    }
}
