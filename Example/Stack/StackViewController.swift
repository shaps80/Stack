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
import Stack

extension NSString {
  
  dynamic var initial: String? {
    guard let char = uppercased.characters.first else { return nil }
    return String(char)
  }
  
}

class StackViewController: DataViewController {
  
  // MARK: Stack Configuration, Add, Delete
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let stack = Stack.defaultStack()
    
    // Now lets setup a query for `Person`, sorting by the person's `name`
//    let name = "Anne"
//    let query = Query<Person>().filter("%K == %@", "name", name)
//    let query = Query<Person>().filter("name == 'Anne'")
    let query = Query<Person>().sort(byKey: "name.initial").sort(byKey: "name", direction: .descending)
    
    // We can now use a convenience init on `NSFetchedResultsController`
    fetchedResultsController = try! stack.newFetchedResultsController(query: query, sectionNameKeyPath: "name.initial")
    fetchedResultsController.delegate = self

    // in your application you may do this lazily
    try? fetchedResultsController.performFetch()
  }
  
  private func add(person name: NSString) {
    let stack = Stack.defaultStack()

    // In order to insert, we need to use a `write` transaction
    stack.write(transaction: { (transaction) -> Void in
      // First, lets insert a new `Person` into CoreData
      let person = try transaction.fetchOrInsert(key: "name", identifier: name) as Person
      
      // when the transaction completes it will automatically persist for us -- updating the UI along with it
      print("Stack: Inserted -- \(person) -- %@", Thread.current)
    }) { (error) -> Void in
      if error != nil { print(error) }
    }
  }
  
  override func delete(atIndexPath indexPath: IndexPath) {
    let stack = Stack.defaultStack()
    let person = fetchedResultsController.object(at: indexPath) as! Person
    
    DispatchQueue.global(qos: .userInitiated).async {
      // In order to delete, we need to use a `write` transaction
      stack.write(transaction: { (transaction) -> Void in
        // first we need to copy the object into the current transaction
        let person = transaction.copy(object: person)
        
        // now we can delete it
        try transaction.delete(objects: person)
        
        // when the transaction completes it will automatically persist for us -- updating the UI along with it
        print("Stack: Deleted -- \(person) -- %@", Thread.current)
        
        }, completion: { (error) -> Void in
          if error != nil { print(error) }
      })
    }
  }
  
  // MARK: AlertControllers
  
  override func add(sender: AnyObject?) {
    let controller = UIAlertController(title: "Stack", message: "Enter a name for this person", preferredStyle: .alert)
    
    controller.addTextField { (field) in
      field.placeholder = "name"
    }
    
    controller.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (action) -> Void in
      guard let field = controller.textFields?.first else { return }
      guard let name = field.text else { return }

      self.add(person: name as NSString)
    }))
    
    controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    present(controller, animated: true, completion: nil)
  }
  
  func handleError(error: Error) {
    let controller = UIAlertController(title: "Stack", message: "\(error)", preferredStyle: .alert)
    controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    present(controller, animated: true, completion: nil)
  }

}

