//
//  Transaction.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

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
    guard let entityName = stack.entityNameForManagedObjectClass(T) where entityName != NSStringFromClass(NSManagedObject) else {
      throw StackError.EntityNameNotFoundForClass(T)
    }
    
    guard let object = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as? T else {
      throw StackError.EntityNotFoundInStack(stack, entityName)
    }
    
    return object as T
  }
  
  /**
   Fetches (or inserts if not found) an entity with the specified identifier
   */
  public func fetchOrInsert<T: NSManagedObject, U: StackManagedKey>(key: String, identifier: U) throws -> T {
    let results = try fetchOrInsert(key, identifiers: [identifier]) as [T]
    return results.first!
  }
  
  /**
   Fetches (or inserts if not found) entities with the specified identifiers
   */
  public func fetchOrInsert<T : NSManagedObject, U : StackManagedKey>(key: String, identifiers: [U]) throws -> [T] {
    let query = Query<T>(key: key, identifiers: identifiers)
    let request = try fetchRequest(query)
    
    guard let results = try context.executeFetchRequest(request) as? [T] else {
      throw StackError.FetchError(nil)
    }
    
    if results.count == identifiers.count {
      return results
    }
    
    var objects = [T]()
    if let existingIds = (results as NSArray).valueForKey(key) as? [U] {
      for id in identifiers {
        if !existingIds.contains(id) {
          print("adding \(id)")
          let result = try insert() as T
          result.setValue(id, forKeyPath: key)
          objects.append(result)
        }
      }
    }
    
    return objects as [T]
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
      context.deleteObject(object)
    }
  }
  
}

