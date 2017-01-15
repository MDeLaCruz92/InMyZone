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
    tableView.backgroundColor = UIColor.black
    tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
    tableView.indicatorStyle = .white
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
    return sectionInfo.name.uppercased()
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let labelRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 14, width: 300, height: 14)
    let label = UILabel(frame: labelRect)
    label.font = UIFont.boldSystemFont(ofSize: 11)
    
    label.text = tableView.dataSource!.tableView!(tableView, titleForHeaderInSection: section)
    
    label.textColor = UIColor(white: 1.0, alpha: 0.4)
    label.backgroundColor = UIColor.clear
    
    let separatorRect = CGRect(x: 15,
                               y: tableView.sectionHeaderHeight - 0.5,
                               width: tableView.bounds.size.width - 15,
                               height: 0.5)
    let separator = UIView(frame: separatorRect)
    separator.backgroundColor = tableView.separatorColor
    
    let viewRect = CGRect(x: 0, y: 0, width: tableView.bounds.size.width,
                          height: tableView.sectionHeaderHeight)
    let view = UIView(frame: viewRect)
    view.backgroundColor = UIColor(white: 0, alpha: 0.85)
    view.addSubview(label)
    view.addSubview(separator)
    return view
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
