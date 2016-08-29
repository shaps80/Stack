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

/// A transaction provides a type-safe implementation for performing any write action to CoreData
public class Transaction: Readable, Writable {
  
  /// Returns the stack associated with this transaction
  private(set) var stack: Stack
  
  /// Returns the context associated with this transaction
  private(set) var context: NSManagedObjectContext
  
  /**
   Internal: Initializes a new transaction for the specified Stack
   
   - parameter stack:   The stack this transaction will be applied to
   - parameter context: The context this transaction will be applied to
   
   - returns: A new Transaction
   */
  init(stack: Stack, context: NSManagedObjectContext) {
    self.stack = stack
    self.context = context
  }
  
  /**
   Inserts a new entity of the specified class. Usage: `insert() as EntityName`
   */
  public func insert<T: NSManagedObject>() throws -> T {
    guard let entityName = stack.entityNameForManagedObjectClass(T), entityName != NSStringFromClass(NSManagedObject) else {
      throw StackError.EntityNameNotFoundForClass(T)
    }
    
    guard let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? T else {
      throw StackError.EntityNotFoundInStack(stack, entityName)
    }
    
    return object as T
  }
  
  /**
   Fetches (or inserts if not found) an entity with the specified identifier
   */
  public func fetchOrInsert<T: NSManagedObject, U: StackManagedKey>(key: String, identifier: U) throws -> T {
    let results = try fetchOrInsert(key: key, identifiers: [identifier]) as [T]
    return results.first!
  }
  
  /**
   Fetches (or inserts if not found) entities with the specified identifiers
   */
  public func fetchOrInsert<T : NSManagedObject, U : StackManagedKey>(key: String, identifiers: [U]) throws -> [T] {
    let query = Query<T>(key: key, identifiers: identifiers)
    let request = try fetchRequest(query: query)
    
    guard let results = try context.fetch(request) as? [T] else {
      throw StackError.FetchError(nil)
    }
    
    if results.count == identifiers.count {
      return results
    }
    
    var objects = [T]()
    if let existingIds = (results as NSArray).value(forKey: key) as? [U] {
      for id in identifiers {
        if !existingIds.contains(id) {
          let result = try insert() as T
          result.setValue(id, forKeyPath: key)
          objects.append(result)
        }
      }
    }
    
    return objects as [T]
  }
  
  /**
   Performs a fetch using the specified NSManagedObjectID
   
   - parameter objectID: The objectID to use for this fetch
   
   - throws: An error will be thrown if the query cannot be performed
   
   - returns: The resulting object or nil
   */
  public func fetch<T: NSManagedObject>(objectWithID objectID: NSManagedObjectID) throws -> T? {
    let stack = _stack()
    let context = stack.currentThreadContext()
    
    return try context.existingObject(with: objectID) as? T
  }
  
  /**
   Deletes the specified objects
   */
  public func delete<T: NSManagedObject>(objects: T...) throws {
    try delete(objects: objects)
  }
  
  /**
   Deletes the specified objects
   */
  public func delete<T: NSManagedObject>(objects objects: [T]) throws {
    for object in objects {
      context.delete(object)
    }
  }
  
}

