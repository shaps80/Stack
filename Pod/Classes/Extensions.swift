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
    assert(NSThread.isMainThread())
    let request = try stack.fetchRequest(query)
    self.init(fetchRequest: request, managedObjectContext: stack.currentThreadContext(), sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
  }
  
}

extension NSManagedObjectContext {
  
  enum SaveResult: ErrorType {
    case Success
    case Failed(NSError)
  }
  
  func save(synchronous: Bool, completion: (NSManagedObjectContext.SaveResult) -> ()) {
    let saveBlock: () -> () = { [unowned self] in
      if !self.hasChanges {
        completion(.Success)
        return
      }
      
      do {
        try self.save()
      } catch {
        completion(.Failed(error as NSError))
        return
      }
      
      if self.parentContext != nil {
        self.parentContext?.save(synchronous, completion: completion)
      } else {
        completion(.Success)
      }
    }
    
    if synchronous {
      performBlockAndWait(saveBlock)
    } else {
      performBlock(saveBlock)
    }
    
  }
  
}