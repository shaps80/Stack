/*
  Copyright © 2015 Shaps Mohsenin. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY SHAPS MOHSENIN `AS IS' AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
  EVENT SHALL THE APP BUSINESS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
