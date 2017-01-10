//
//  LocationsVC.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 1/3/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class LocationsVC: UITableViewController {
  var managedObjectContext: NSManagedObjectContext!
  var locations = [Location]()
  
  lazy var fetchedResultsController: NSFetchedResultsController<Location> = {
    let fetchRequest = NSFetchRequest<Location>()
    
    let entity = Location.entity()
    fetchRequest.entity = entity
    
    let sortDescriptor1 = NSSortDescriptor(key: "category", ascending: true)
    let sortDescriptor2 = NSSortDescriptor(key: "date", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]
    
    fetchRequest.fetchBatchSize = 20
    
    let fetchedResultsController = NSFetchedResultsController(
      fetchRequest: fetchRequest,
      managedObjectContext: self.managedObjectContext,
      sectionNameKeyPath: "category",
      cacheName: "Locations")
    
    fetchedResultsController.delegate = self
    return fetchedResultsController
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    performFetch()
    navigationItem.rightBarButtonItem = editButtonItem
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "EditLocation" {
      let navigationController = segue.destination as! UINavigationController
      let controller = navigationController.topViewController as! LocationDetailsVC
      controller.managedObjectContext = managedObjectContext
      
      if let indexPath = tableView.indexPath(for: sender as! UITableViewCell) {
        let location = fetchedResultsController.object(at: indexPath)
        controller.locationToEdit = location
      }
    }
  }
  
  // MARK: - UITableViewDataSource
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionInfo = fetchedResultsController.sections![section]
    return sectionInfo.numberOfObjects
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
          withIdentifier: "LocationCell", for: indexPath) as! LocationCell
    
    let location = fetchedResultsController.object(at: indexPath)
    cell.configure(for: location)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let location = fetchedResultsController.object(at: indexPath)
      
      location.removePhotoFile()  // deleting location happens here.
      managedObjectContext.delete(location)
      
      do {
        try managedObjectContext.save()
      } catch {
        fatalCoreDataError(error)
      }
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return fetchedResultsController.sections!.count
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let sectionInfo = fetchedResultsController.sections![section]
    return sectionInfo.name
  }
  
  func performFetch() {
    do {
      try fetchedResultsController.performFetch()
    } catch {
      fatalCoreDataError(error)
    }
  }
  
  deinit {
    fetchedResultsController.delegate = nil
  }
  
}
