//
//  DataViewController.swift
//  Stack
//
//  Created by Shaps Mohsenin on 25/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import CoreData

class DataViewController: UITableViewController, NSFetchedResultsControllerDelegate {
  
  
  /*
  
  -------------------------------------------------------------------------
  This class is purely NSFetchedResultsController boilerplate code!
  
  Please checkout StackViewController for example code.
  -------------------------------------------------------------------------
  
  */
  
  
  
  
  
  
  // MARK: Subclassers Methods
  
  @IBAction func add(sender: AnyObject?) { /* implement in subclass */ }
  func delete(atIndexPath indexPath: NSIndexPath) { /* implement in subclass */ }

  // MARK: TableView DataSource
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController.fetchedObjects?.count ?? 0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
    
    if let person = fetchedResultsController.objectAtIndexPath(indexPath) as? Person {
      cell.textLabel?.text = person.name ?? "Unknown"
    }

    return cell
  }
  
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      delete(atIndexPath: indexPath)
    }
  }
  
  // MARK: FetchedResultsController Delegate
  
  var fetchedResultsController: NSFetchedResultsController!
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    tableView.beginUpdates()
    
    if !NSThread.isMainThread() {
      fatalError("Fetched Results Controller executed off the main thread!!")
    }
  }
  
  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    
    switch type {
    case .Insert:
      tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
    case .Delete:
      tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
    default:
      break
    }
  }
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
      print("FRC: Inserted -- \(anObject)")
    case .Delete:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
      print("FRC: Deleted -- \(anObject)")
    case .Update:
      tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
    }
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    tableView.endUpdates()
  }

}
