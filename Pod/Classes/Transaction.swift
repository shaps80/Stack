//
//  Transaction.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import CoreData

// MARK: Transaction

public protocol WriteSupport {
  
  
  
}

public class Transaction {
  
  private(set) var stack: Stack
  private(set) var context: NSManagedObjectContext
  
  init(stack: Stack, context: NSManagedObjectContext) {
    self.stack = stack
    self.context = context
  }
  
  public func copy<T>(object: T) -> T {
    // mock
    let p = NSManagedObject() as! T
    return p
  }
  
  public func copy<T>(objects objs: T...) -> [T] {
    return objs.map({ $0 })
  }
  
  public func copy<T>(objects: [T]) -> [T] {
    return objects
  }
  
  public func insert<T: NSManagedObject>() throws -> T {
    guard let entityName = stack.entityNameForManagedObjectClass(T) where entityName != NSStringFromClass(NSManagedObject) else {
      throw StackError.EntityNameNotFoundForClass(T)
    }
    
    guard let object = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: stack.currentThreadContext()) as? T else {
      throw StackError.EntityNotFoundInStack(stack, entityName)
    }
    
    return object
  }
  
  public func insertOrFetch<T: NSManagedObject>(key: String, identifier: AnyObject) throws -> T {
    return try insert([key: identifier]) as! T
  }
  
  public func insertOrFetch<T: NSManagedObject>(key: String, identifiers: [AnyObject]) throws -> [T] {
    var objects = [T]()
    
    for id in identifiers {
      if let obj = try? insertOrFetch(key, identifier: id) as T {
        objects.append(obj)
      }
    }
    
    return objects
  }
  
  public func insert<T: NSManagedObject>(attributes: [String: AnyObject]) throws -> T? {
    if let object = try? insert() as T {
      object.setValuesForKeysWithDictionary(attributes)
      return object
    }
    
    return nil
  }
  
  public func delete<T>(objects: T...) {
  }
  
  public func delete<T>(objects objects: [T]) {
  }
  
}



