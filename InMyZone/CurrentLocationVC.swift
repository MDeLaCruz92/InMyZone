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
import QuartzCore
import AudioToolbox

class CurrentLocationVC: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate {
  
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var tagButton: UIButton!
  @IBOutlet weak var getButton: UIButton!
  @IBOutlet weak var latitudeTextLabel: UILabel!
  @IBOutlet weak var longitudeTextLabel: UILabel!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var backGroundView: UIImageView!
  
  let locationManager = CLLocationManager()
  let geoCoder = CLGeocoder()     // object that will perform the geocoding
  
  var timer: Timer?
  var location: CLLocation?
  var placemark: CLPlacemark?     // contains the address results
  var updatingLocation = false
  var performingReverseGeocoding = false
  var logoVisible = false
  var lastGeocodingError: Error?
  var lastLocationError: Error?
  var managedObjectContext: NSManagedObjectContext!
  var soundID: SystemSoundID = 0
  
  lazy var logoButton: UIButton = {
    let button = UIButton(type: .custom)
    button.setBackgroundImage(UIImage(named: "MyZoneIcon"), for: .normal)
    button.sizeToFit()
    button.addTarget(self, action: #selector(getLocation), for: .touchUpInside)
    button.center.x = self.view.bounds.midX
    button.center.y = 220
    return button
  }()
  
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
    if logoVisible {
      hideLogoView()
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
    backgroundLoop()
    updateLabels()
    configureGetButton()
    loadSoundEffect("Magic.caf")
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "MarkLocation" {
      let navigationController = segue.destination as! UINavigationController
      let controller = navigationController.topViewController as! LocationDetailsVC
      
      controller.coordinate = location!.coordinate
      controller.placemark = placemark
      controller.managedObjectContext = managedObjectContext
    }
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
        
        // chose closure over a delegate because using a delegate would need to write one or more separate methods.
        geoCoder.reverseGeocodeLocation(newLocation, completionHandler: { placemarks, error in
          print("*** Found placemarks: \(placemarks), error: \(error)")
          
          // defensive programming
          self.lastGeocodingError = error
          if error == nil, let p = placemarks, !p.isEmpty {
            if self.placemark == nil {
              print("*** FIRST TIME!")
              self.playSoundEffect()
            }
            
            self.placemark = p.last!
          } else {
            self.placemark = nil
          }
          
          self.performingReverseGeocoding = false
          self.updateLabels()
        })
      }
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
      latitudeTextLabel.isHidden = false
      longitudeTextLabel.isHidden = false
    } else {
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      addressLabel.text = ""
      tagButton.isHidden = true
      
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
        statusMessage = ""
        showLogoView()
      }
      messageLabel.text = statusMessage
      latitudeTextLabel.isHidden = true
      longitudeTextLabel.isHidden = true
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
    let spinnerTag = 1000
    
    if updatingLocation {
      getButton.setTitle("Stop", for: .normal)
      
      if view.viewWithTag(spinnerTag) == nil {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
        spinner.center = messageLabel.center
        spinner.center.y += spinner.bounds.size.height/2 + 15
        spinner.startAnimating()
        spinner.tag = spinnerTag
        containerView.addSubview(spinner)
      }
    } else {
      getButton.setTitle("Locate My Zone", for: .normal)
      
      if let spinner = view.viewWithTag(spinnerTag) {
        spinner.removeFromSuperview()
      }
    }
  }
  
  func string(from placemark: CLPlacemark) -> String {
    var line1 = ""
    line1.add(text: placemark.subThoroughfare)
    line1.add(text: placemark.thoroughfare, separatedBy: " ")
    
    var line2 = ""
    line2.add(text: placemark.locality)
    line2.add(text: placemark.administrativeArea, separatedBy: " ")
    line2.add(text: placemark.postalCode, separatedBy: " ")
    
    line1.add(text: line2, separatedBy: "\n")
    return line1
  }
  
  func showLocationServicesDeniedAlert() {
    let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    
    alert.addAction(okAction)
    present(alert, animated: true, completion: nil)
  }
  
  // MARK: - Logo View
  func showLogoView() {
    if !logoVisible {
      logoVisible = true
      containerView.isHidden = true
      view.addSubview(logoButton)
    }
  }
  
  func hideLogoView() {
    if !logoVisible { return }
    
    logoVisible = false
    containerView.isHidden = false
    containerView.center.x = view.bounds.size.width * 2
    containerView.center.y = 40 + containerView.bounds.size.height / 2
    
    let centerX = view.bounds.midX
    
    let panelMover = CABasicAnimation(keyPath: "position")
    panelMover.isRemovedOnCompletion = false
    panelMover.fillMode = kCAFillModeForwards
    panelMover.duration = 0.6
    panelMover.fromValue = NSValue(cgPoint: containerView.center)
    panelMover.toValue = NSValue(cgPoint: CGPoint(x: centerX, y: containerView.center.y))
    panelMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
    panelMover.delegate = self
    containerView.layer.add(panelMover, forKey: "panelMover")
    
    let logoMover = CABasicAnimation(keyPath: "position")
    logoMover.isRemovedOnCompletion = false
    logoMover.fillMode = kCAFillModeForwards
    logoMover.duration = 0.5
    logoMover.fromValue = NSValue(cgPoint: logoButton.center)
    logoMover.toValue = NSValue(cgPoint: CGPoint(x: -centerX, y: logoButton.center.y))
    logoMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
    logoButton.layer.add(logoMover, forKey: "logoMover")
    
    let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
    logoRotator.isRemovedOnCompletion = false
    logoRotator.fillMode = kCAFillModeForwards
    logoRotator.duration = 0.5
    logoRotator.fromValue = 0.0
    logoRotator.toValue = -2 * M_PI
    logoRotator.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
    logoButton.layer.add(logoRotator, forKey: "logoRotator")
  }
  
  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    containerView.layer.removeAllAnimations()
    containerView.center.x = view.bounds.size.width / 2
    containerView.center.y = 40 + containerView.bounds.size.height / 2
    
    logoButton.layer.removeAllAnimations()
    logoButton.removeFromSuperview()
  }
  
  // MARK: - Sound Effect
  func loadSoundEffect(_ name: String) {
    if let path = Bundle.main.path(forResource: name, ofType: nil) {
      let fileURL = URL(fileURLWithPath: path, isDirectory: false)
      let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
      
      if error != kAudioServicesNoError {
        print("Error code \(error) loading sound at path: \(path)")
      }
    }
  }
  
  func unloadSoundEffect() {
    AudioServicesDisposeSystemSoundID(soundID)
    soundID = 0
  }
  
  func playSoundEffect() {
    AudioServicesPlaySystemSound(soundID)
  }
  
  // MARK: - background view
  func backgroundLoop() {
    timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { [weak self] _ in self?.backgroundTransition()
    }
  }
  
  func backgroundTransition() {
    let rolls = arc4random_uniform(15) + 1
    let toImage = UIImage(named: "wp\(rolls)")
    
    UIView.transition(with: backGroundView, duration: 2, options: [.transitionCrossDissolve],
                      animations: { self.backGroundView.image = toImage }, completion: nil)
  }
  
}

