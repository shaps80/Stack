//
//  Transaction.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import CoreData

// MARK: Transaction

public class Transaction: Readable, Writable {
  
  private(set) var stack: Stack
  private(set) var context: NSManagedObjectContext
  
  init(stack: Stack, context: NSManagedObjectContext) {
    self.stack = stack
    self.context = context
  }
  
  public func copy<T: NSManagedObject>(object: T) -> T {
    let objects = copy([object]) as [T]
    return objects.first!
  }
  
  public func copy<T: NSManagedObject>(objects objs: T...) -> [T] {
    return copy(objs)
  }
  
  public func copy<T: NSManagedObject>(objects: [T]) -> [T] {
    var results = [T]()
    
    for object in objects {
      if let obj = context.objectWithID(object.objectID) as? T {
        results.append(obj)
      }
    }
    
    return results
  }
  
  public func insert<T: NSManagedObject>() throws -> T {
    guard let entityName = stack.entityNameForManagedObjectClass(T) where entityName != NSStringFromClass(NSManagedObject) else {
      throw StackError.EntityNameNotFoundForClass(T)
    }
    
    guard let object = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: _stack().currentThreadContext()) as? T else {
      throw StackError.EntityNotFoundInStack(stack, entityName)
    }
    
    return object
  }
  
  public func insertOrFetch<T: NSManagedObject, U: StackManagedKey>(key: String, identifier: U) throws -> T {
    let results = try insertOrFetch(key, identifiers: [identifier]) as [T]
    return results.first!
  }
  
  public func insertOrFetch<T : NSManagedObject, U : StackManagedKey>(key: String, identifiers: [U]) throws -> [T] {
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
    
    return objects
  }
  
  public func delete<T: NSManagedObject>(objects: T...) throws {
    try delete(objects: objects)
  }
  
  public func delete<T: NSManagedObject>(objects objects: [T]) throws {
    for object in objects {
      if object.managedObjectContext != _stack().currentThreadContext() {
        throw StackError.DeleteFailed("An NSManagedObjectContext cannot delete objects in other contexts")
      }
      
      context.deleteObject(object)
    }
  }
  
}

