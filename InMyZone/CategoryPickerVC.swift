//
//  CategoryPickerVC.swift
//  InMyZone
//
//  Created by Michael De La Cruz on 1/1/17.
//  Copyright © 2017 Michael De La Cruz. All rights reserved.
//

import UIKit

class CategoryPickerVC: UITableViewController {
  var selectedCategoryName = ""
  
  let categories = [
    "No Category",
    "Apple Store",
    "Bar",
    "Bookstore",
    "Breakfast zone",
    "Club",
    "Coffee Shop",
    "Grocery Store",
    "Gym",
    "Highway",
    "House",
    "Mall",
    "Fast Food Spot",
    "My Personal Zone",
    "Landmark",
    "Park",
    "School",
    "Shopping Zone",
    "Station",
    "Store",
    "Work"]
  
  var selectedIndexPath = IndexPath()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.backgroundColor = UIColor.black
    tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
    tableView.indicatorStyle = .white
    
    for i in 0..<categories.count {
      if categories[i] == selectedCategoryName {
        selectedIndexPath = IndexPath(row: i, section: 0)
        break
      }
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "PickedCategory" {
      let cell = sender as! UITableViewCell
      if let indexPath = tableView.indexPath(for: cell) {
        selectedCategoryName = categories[indexPath.row]
      }
    }
  }
  
  // MARK: - UITableViewDataSource
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return categories.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    
    let categoryName = categories[indexPath.row]
    cell.textLabel!.text = categoryName
    
    if categoryName == selectedCategoryName {
      cell.accessoryType = .checkmark
    } else {
      cell.accessoryType = .none
    }
    return cell
  }
  
  // MARK: - UITableViewDelegate
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row != selectedIndexPath.row {
      if let newCell = tableView.cellForRow(at: indexPath) {
        newCell.accessoryType = .checkmark
      }
      if let oldCell = tableView.cellForRow(at: selectedIndexPath) {
        oldCell.accessoryType = .none
      }
      selectedIndexPath = indexPath
    }
  }
  
  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.backgroundColor = UIColor.black
    
    if let textLabel = cell.textLabel {
      textLabel.textColor = UIColor.white
      textLabel.highlightedTextColor = textLabel.textColor
    }
    
    let selectionView = UIView(frame: CGRect.zero)
    selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
    cell.multipleSelectionBackgroundView = selectionView
  }
}
