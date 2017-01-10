//
//  MapVCExtension.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 1/4/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import MapKit

extension MapVC: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation is Location else {
      return nil
    }
    let identifier = "Location"
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
    
    if annotationView == nil {
      let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
      
      pinView.isEnabled = true
      pinView.canShowCallout = true
      pinView.animatesDrop = false
      pinView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
      
      let rightButton = UIButton(type: .detailDisclosure)
      rightButton.addTarget(self, action: #selector(showLocationDetails), for: .touchUpInside)
      pinView.rightCalloutAccessoryView = rightButton
      annotationView = pinView
    }
    if let annotationView = annotationView {
      annotationView.annotation = annotation
      
      let button = annotationView.rightCalloutAccessoryView as! UIButton
      if let index = locations.index(of: annotation as! Location) {
        button.tag = index
      }
    }
    return annotationView
  }
}

extension MapVC: UINavigationBarDelegate {
  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .topAttached
  }
}
