//
//  NSFetchedResultsController+Stack.swift
//  Stack
//
//  Created by Shaps Mohsenin on 26/11/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import CoreData

extension NSFetchedResultsController {
  
  public convenience init<T: NSManagedObject>(stack: Stack, query: Query<T>, sectionNameKeyPath: String? = nil, cacheName: String? = nil) throws {
    precondition(NSThread.isMainThread(), "You must ONLY create an NSFetchedResultsController from the Main Thread")
    let request = try stack.fetchRequest(query)
    self.init(fetchRequest: request, managedObjectContext: stack.currentThreadContext(), sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
  }
  
}

extension NSManagedObjectContext {
  
  func save(synchronous: Bool, completion: ((NSError?) -> ())?) {
    let saveBlock: () -> () = { [unowned self] in
      if !self.hasChanges {
        completion?(nil)
        return
      }
      
      do {
        try self.save()
      } catch {
        completion?(error as NSError)
        return
      }
      
      if self.parentContext != nil {
        self.parentContext?.save(synchronous, completion: completion)
      } else {
        completion?(nil)
      }
    }
    
    if synchronous {
      performBlockAndWait(saveBlock)
    } else {
      performBlock(saveBlock)
    }
    
  }
  
}