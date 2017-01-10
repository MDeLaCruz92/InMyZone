//
//  Location+CoreDataProperties.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 1/2/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation


extension Location {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
    return NSFetchRequest<Location>(entityName: "Location");
  }
  
  @NSManaged public var latitude: Double
  @NSManaged public var longitude: Double
  @NSManaged public var date: Date
  @NSManaged public var locationDescription: String
  @NSManaged public var category: String
  @NSManaged public var placemark: CLPlacemark?
  @NSManaged var photoID: NSNumber?
  
}
