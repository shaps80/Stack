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
  func delete(atIndexPath indexPath: IndexPath) { /* implement in subclass */ }

  // MARK: TableView DataSource
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return fetchedResultsController.sections?.count ?? 0
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard fetchedResultsController.sections?.count > 0 else {
      return 0
    }
    
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
    
    if let person = fetchedResultsController.object(at: indexPath) as? Person {
      cell.textLabel?.text = person.name ?? "Unknown"
    }

    return cell
  }
  
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
    if editingStyle == .delete {
      delete(atIndexPath: indexPath)
    }
  }
  
  // MARK: FetchedResultsController Delegate
  
  var fetchedResultsController: NSFetchedResultsController<NSManagedObject>!
  
  private func controllerWillChangeContent(controller: NSFetchedResultsController<NSManagedObject>) {
    tableView.beginUpdates()
    
    if !Thread.isMainThread {
      fatalError("Fetched Results Controller executed off the main thread!!")
    }
  }
  
  func controller(controller: NSFetchedResultsController<NSManagedObject>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    
    switch type {
    case .insert:
      tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
    case .delete:
      tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
    default:
      break
    }
  }
  
  private func controller(controller: NSFetchedResultsController<NSManagedObject>, didChangeObject anObject: AnyObject, atIndexPath indexPath: IndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch type {
    case .insert:
      tableView.insertRows(at: [newIndexPath!], with: .automatic)
      print("FRC: Inserted -- \(anObject)")
    case .delete:
      tableView.deleteRows(at: [indexPath!], with: .automatic)
      print("FRC: Deleted -- \(anObject)")
    case .update:
      tableView.reloadRows(at: [indexPath!], with: .automatic)
    case .move:
      tableView.deleteRows(at: [indexPath!], with: .automatic)
      tableView.insertRows(at: [newIndexPath!], with: .automatic)
    }
  }
  
  private func controllerDidChangeContent(controller: NSFetchedResultsController<NSManagedObject>) {
    tableView.endUpdates()
  }

}
