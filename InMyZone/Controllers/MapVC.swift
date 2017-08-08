//
//  MapVC.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 1/4/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  
  var locations = [Location]()
  
  var managedObjectContext: NSManagedObjectContext! {
    didSet {
      NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: OperationQueue.main) { notification in
        if self.isViewLoaded {
          self.updateLocations()
        }
      }
    }
  }
  
  @IBAction func showUser() {
    let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
    mapView.setRegion(mapView.regionThatFits(region), animated: true)
  }
  
  @IBAction func showLocations() {
    let theRegion = region(for: locations)
    mapView.setRegion(theRegion, animated: true)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateLocations()
    
    if !locations.isEmpty {
      showLocations()
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "EditLocation" {
      let navigationController = segue.destination as! UINavigationController
      let controller = navigationController.topViewController as! LocationDetailsVC
      
      controller.managedObjectContext = managedObjectContext
      
      let button = sender as! UIButton
      let location = locations[button.tag]
      controller.locationToEdit = location
    }
  }
  
  func updateLocations() {
    mapView.removeAnnotations(locations)
    
    let entity = Location.entity()
    
    let fetchRequest = NSFetchRequest<Location>()
    fetchRequest.entity = entity
    
    locations = try! managedObjectContext.fetch(fetchRequest)
    mapView.addAnnotations(locations)
  }
  
  func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
    let region: MKCoordinateRegion
    
    switch annotations.count {
    case 0:
      region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
      
    case 1:
      let annotation = annotations[annotations.count - 1]
      region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
      
    default:
      var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
      var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
      
      for annotation in annotations {
        topLeftCoord.latitude = max(topLeftCoord.latitude, annotation.coordinate.latitude)
        topLeftCoord.longitude = min(topLeftCoord.longitude, annotation.coordinate.longitude)
        bottomRightCoord.latitude = min(bottomRightCoord.latitude, annotation.coordinate.latitude)
        bottomRightCoord.longitude = max(bottomRightCoord.longitude, annotation.coordinate.longitude)
      }
      
      let center = CLLocationCoordinate2D(
        latitude: topLeftCoord.latitude -
          (topLeftCoord.latitude - bottomRightCoord.latitude) / 2,
        longitude: topLeftCoord.longitude -
          (topLeftCoord.longitude - bottomRightCoord.longitude) / 2)
      let extraSpace = 1.1
      let span = MKCoordinateSpan(latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace, longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace)
      
      region = MKCoordinateRegion(center: center, span: span)
    }
    return mapView.regionThatFits(region)
  }
  
  func showLocationDetails(_ sender: UIButton) {
    performSegue(withIdentifier: "EditLocation", sender: sender)
  }
  
}
