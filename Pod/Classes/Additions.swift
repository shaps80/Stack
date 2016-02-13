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


