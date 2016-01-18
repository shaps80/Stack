//
//  Transaction.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import CoreData

// MARK: Transaction

public enum TransactionError: ErrorType {
  case InvalidEntityName(String)
  case EntityNotFound(String)
  case InvalidThread
}

public class Transaction {
  
  private(set) var stack: Stack
  private(set) var context: NSManagedObjectContext
  
  public init() {
    self.stack = Stack.defaultStack()
    self.context = NSManagedObjectContext()
  }
  
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
      throw TransactionError.InvalidEntityName(NSStringFromClass(T))
    }
    
    guard let object = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.stack.rootContext) as? T else {
      throw TransactionError.EntityNotFound(entityName)
    }
    
    return object
  }
  
  public func insertOrFetch<T: NSManagedObject>(key: String, identifier: AnyObject) throws -> T {
    return try insert([key: identifier]) as T
  }
  
  public func insertOrFetch<T: NSManagedObject>(key: String, identifiers: [AnyObject]) throws -> [T] {
    var objects = [T]()
    
    for id in identifiers {
      let obj = try insertOrFetch(key, identifier: id) as T
      objects.append(obj)
    }
    
    return objects
  }
  
  public func insert<T: NSManagedObject>(attributes: [String: AnyObject]) throws -> T {
    let object = try insert() as T
    object.setValuesForKeysWithDictionary(attributes)
    return object
  }
  
  public func delete<T>(objects objs: T...) throws {
    throw TransactionError.InvalidThread
  }
  
  public func delete<T>(objects: [T]) throws {
    throw TransactionError.InvalidThread
  }
  
}



