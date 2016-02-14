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

class ViewController: DataViewController {
  
  // MARK: Configure, Add, Delete
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    // this should be configured BEFORE the first time you access defaultStack()
    Stack.configureDefaults { (config) -> () in
      
      // Stack supports various configurations, here we will setup a stack to use only the mainThread context for all operations
      config.stackType = .ParentChild // .MainThreadOnly // .ManualMerge
      
      // We can also define the persistence type
      config.persistenceType = .SQLite // .MemoryOnly // .Binary
      
      // checkout `config` to see what other options you can configure and what the defaults are
    }
    
    // Now we have configured the stack, lets grab it
    let stack = Stack.defaultStack()
    let person = try! stack.fetch("name", identifier: "123") as? Person
    print(person?.name)
    
    // Now lets setup a query for `Person`, sorting by the person's `name`
//    let name = "Anne"
//    let query = Query<Person>().filter("%K == %@", "name", name)
//    let query = Query<Person>().filter("name == 'Anne'")
    let query = Query<Person>().sort(byKey: "name", direction: .Ascending)
    let results = try! stack.fetch(query)
    results.first?.name
    
    // We can now use a convenience init on `NSFetchedResultsController`
    fetchedResultsController = try! NSFetchedResultsController(stack: stack, query: query)
    fetchedResultsController.delegate = self

    // in your application you may do this lazily
    try! fetchedResultsController.performFetch()
  }
  
  private func add(person name: NSString) {
    let stack = Stack.defaultStack()

    // In order to insert, we need to use a `write` transaction
    stack.write({ (transaction) -> Void in
      // First, lets insert a new `Person` into CoreData
      let person = try transaction.fetchOrInsert("name", identifier: name) as Person
      
      // when the transaction completes it will automatically persist for us -- updating the UI along with it
      print("Stack: Inserted -- \(person) -- %@", NSThread.currentThread())
    }) { (error) -> Void in
      if error != nil { print(error) }
    }
  }
  
  override func delete(atIndexPath indexPath: NSIndexPath) {
    let stack = Stack.defaultStack()
    let person = fetchedResultsController.objectAtIndexPath(indexPath) as! Person
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
      // In order to delete, we need to use a `write` transaction
      stack.write({ (transaction) -> Void in
        // first we need to copy the object into the current transaction
        let person = transaction.copy(person)
        
        // now we can delete it
        try transaction.delete(person)
        
        // when the transaction completes it will automatically persist for us -- updating the UI along with it
        print("Stack: Deleted -- \(person) -- %@", NSThread.currentThread())
      }, completion: { (error) -> Void in
        if error != nil { print(error) }
      })
    }
  }
  
  // MARK: AlertControllers
  
  override func add(sender: AnyObject?) {
    let controller = UIAlertController(title: "Stack", message: "Enter a name for this person", preferredStyle: .Alert)
    
    controller.addTextFieldWithConfigurationHandler { (field) -> Void in
      field.placeholder = "name"
    }
    
    controller.addAction(UIAlertAction(title: "Submit", style: .Default, handler: { (action) -> Void in
      if let field = controller.textFields?.first, name = field.text {
          self.add(person: name)
      }
    }))
    
    controller.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
    presentViewController(controller, animated: true, completion: nil)
  }
  
  func handleError(error: ErrorType) {
    let controller = UIAlertController(title: "Stack", message: "\(error)", preferredStyle: .Alert)
    controller.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    presentViewController(controller, animated: true, completion: nil)
  }

}

