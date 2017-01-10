//
//  FirstViewController.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 12/28/16.
//  Copyright © 2016 Michael De La Cruz. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class CurrentLocationVC: UIViewController, CLLocationManagerDelegate {
  
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var tagButton: UIButton!
  @IBOutlet weak var getButton: UIButton!
  
  let locationManager = CLLocationManager()
  let geoCoder = CLGeocoder()     // object that will perform the geocoding
  
  var timer: Timer?
  var location: CLLocation?
  var placemark: CLPlacemark?     // contains the address results
  var updatingLocation = false
  var performingReverseGeocoding = false
  var lastGeocodingError: Error?
  var lastLocationError: Error?
  var managedObjectContext: NSManagedObjectContext!
  
  // This method tells the location manager that the VC is its delegate & want to recieve locations with an accuracy of up to ten meters.
  @IBAction func getLocation() {
    let authStatus = CLLocationManager.authorizationStatus()
    
    if authStatus == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
      return
    }
    
    if authStatus == .denied || authStatus == .restricted {
      showLocationServicesDeniedAlert()
      return
    }
    
    if updatingLocation {
      stopLocationManager()
    } else {
      location = nil
      lastLocationError = nil
      placemark = nil
      lastGeocodingError = nil
      startLocationManager()
    }
    updateLabels()
    configureGetButton()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateLabels()
    configureGetButton()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - CLLocationManagerDelegate
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("didFailWithError \(error)")
    
    // location manager was unable to obtain a location right now
    if (error as NSError).code == CLError.locationUnknown.rawValue {
      return
    }
    
    lastLocationError = error
    
    stopLocationManager()
    updateLabels()
    configureGetButton()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "TagLocation" {
      let navigationController = segue.destination as! UINavigationController
      let controller = navigationController.topViewController as! LocationDetailsVC
      
      controller.coordinate = location!.coordinate
      controller.placemark = placemark
      controller.managedObjectContext = managedObjectContext
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let newLocation = locations.last!
    print("didUpdateLocations \(newLocation)")
    
    // if the time at which the given location object was determined is too long ago (5sec), then this is a so-called cached result
    if newLocation.timestamp.timeIntervalSinceNow < -5 {
      return
    }
    // determine whether new readings are more accurate than previous ones
    if newLocation.horizontalAccuracy < 0 {
      return
    }
    
    var distance = CLLocationDistance(DBL_MAX)
    if let location = location {
      distance = newLocation.distance(from: location)
    }
    // determine if the new reading is more useful than the previous one
    if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
      // clears out any previous errors if there was one
      lastLocationError = nil
      location = newLocation
      updateLabels()
    }
    if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
      print("*** We're done!")
      stopLocationManager()
      configureGetButton()
      
      if distance > 0 {
        performingReverseGeocoding = false
      }
    }
    
    if !performingReverseGeocoding {
      print("*** Going to geocode")
      
      performingReverseGeocoding = true
      // closure over a delegate because using a delegate would need to write one or more separate methods.
      geoCoder.reverseGeocodeLocation(newLocation, completionHandler: { placemarks, error in
        print("*** Found placemarks: \(placemarks), error: \(error)")
        // defensive programming
        self.lastGeocodingError = error
        if error == nil, let p = placemarks, !p.isEmpty {
          self.placemark = p.last!
        } else {
          self.placemark = nil
        }
        
        self.performingReverseGeocoding = false
        self.updateLabels()
      })
    } else if distance < 1 {
      let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
      
      if timeInterval > 10 {
        print("*** Force done!")
        stopLocationManager()
        updateLabels()
        configureGetButton()
      }
    }
  }
  
  func updateLabels() {
    if let location = location {
      //creates a new string object using the format string and the value to replace that string
      latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
      longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
      tagButton.isHidden = false
      messageLabel.text = ""
      
      if let placemark = placemark {
        addressLabel.text = string(from: placemark)
      } else if performingReverseGeocoding {
        addressLabel.text = "Searching for Address..."
      } else if lastGeocodingError != nil {
        addressLabel.text = "Error Finding Address"
      } else {
        addressLabel.text = "No Address Found"
      }
    } else {
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      addressLabel.text = ""
      tagButton.isHidden = true
      messageLabel.text = "Tap 'Get My Location' to Start"
      
      let statusMessage: String
      if let error = lastLocationError as? NSError {
        if error.domain == kCLErrorDomain &&
          error.code == CLError.denied.rawValue {
          statusMessage = "Location Services Disabled"
        } else {
          statusMessage = "Error Getting Location"
        }
      } else if !CLLocationManager.locationServicesEnabled() {
        statusMessage = "Location Services Disabled"
      } else if updatingLocation {
        statusMessage = "Searching..."
      } else {
        statusMessage = "Tap 'Get My Location' to Start"
      }
      
      messageLabel.text = statusMessage
    }
  }
  
  func startLocationManager() {
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
      updatingLocation = true
      
      timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
    }
  }
  
  func stopLocationManager() {
    if updatingLocation {
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updatingLocation = false
      
      if let timer = timer {
        timer.invalidate()
      }
    }
  }
  
  func didTimeOut() {
    print("*** Time out")
    
    if location == nil {
      stopLocationManager()
      
      lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
      updateLabels()
      configureGetButton()
    }
  }
  
  func configureGetButton() {
    if updatingLocation {
      getButton.setTitle("Stop", for: .normal)
    } else {
      getButton.setTitle("Get My Location", for: .normal)
    }
  }
  
  func string(from placemark: CLPlacemark) -> String {
    // Create new string variable for the first line of text
    var line1 = ""
    
    // if the placemark has a subThoroughfare, add it to the string
    if let s = placemark.subThoroughfare {
      line1 += s + ""
    }
    // Adding the thoroughfare is done similarly
    if let s = placemark.thoroughfare {
      line1 += s
    }
    // adds the city, state/province, and zip code
    var line2 = ""
    
    if let s = placemark.locality {
      line2 += s + ""
    }
    if let s = placemark.administrativeArea {
      line2 += s + ""
    }
    if let s = placemark.postalCode {
      line2 += s
    }
    return line1 + "\n" + line2
  }
  
  func showLocationServicesDeniedAlert() {
    let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    
    alert.addAction(okAction)
    present(alert, animated: true, completion: nil)
  }
}

