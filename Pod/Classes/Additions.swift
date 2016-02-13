//
//  NSFetchedResultsController+Stack.swift
//  Stack
//
//  Created by Shaps Mohsenin on 26/11/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import CoreData

/**
 Combines two NSPredicate using [NSCompoundPredicate andPredicateWithSubpredicates:]
 
 - parameter left:  The first NSPredicate
 - parameter right: The second NSPredicate
 
 - returns: An NSCompoundPredicate
 */
public func && (left: NSPredicate, right: NSPredicate) -> NSPredicate {
  return NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [left, right])
}


/**
 Combines two NSPredicate using [NSCompoundPredicate orPredicateWithSubpredicates:]
 
 - parameter left:  The first predicate
 - parameter right: The second predicate
 
 - returns: An NSCompoundPredicate
 */
public func || (left: NSPredicate, right: NSPredicate) -> NSPredicate {
  return NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: [left, right])
}

#if os(iOS)
  
  extension NSFetchedResultsController {
    
    /**
     Provides a convenience initializer for creating an NSFetchedResultsController from a Stack and Query. Note: you are still required to call -performFetch()
     
     - parameter stack:              The stack to use
     - parameter query:              The query to use for configuring this fetched results controller
     - parameter sectionNameKeyPath: The keyPath to use for providing section information (optional)
     - parameter cacheName:          The cache name to use for caching results (optional)
     
     - throws: Throws an error if the fetchRequest cannot be created from the specified query
     
     - returns: A newly configured NSFetchedResultsController.
     */
    public convenience init<T: NSManagedObject>(stack: Stack, query: Query<T>, sectionNameKeyPath: String? = nil, cacheName: String? = nil) throws {
      precondition(NSThread.isMainThread(), "You must ONLY create an NSFetchedResultsController from the Main Thread")
      let request = try stack.fetchRequest(query)
      self.init(fetchRequest: request, managedObjectContext: stack.currentThreadContext(), sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
    }
    
  }
#endif

extension NSManagedObjectContext {
  
  /**
   Provides an internal method for saving NSManagedObjectContext changes
   
   - parameter synchronous: Whether or not this save should be performed synchronously or asynchronously
   - parameter completion:  The completion block to execute when this save completes (may contain an error is the save was unsuccessful)
   */
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


