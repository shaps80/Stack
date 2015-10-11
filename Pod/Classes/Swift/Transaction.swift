//
//  Transaction.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import Foundation

// MARK: Transaction

final class Transaction {
  
  private(set) var stack: Stack
  private(set) var context: NSManagedObjectContext
  
  init(stack: Stack, context: NSManagedObjectContext) {
    self.stack = stack
    self.context = context
  }
  
}

// MARK: Copying

extension Transaction {
  
  func copy<T: NSManagedObject>(object: T) -> T {
    // mock
    let p = Person() as! T
    return p
  }
  
  func copy<T: NSManagedObject>(objects objs: T...) -> [T] {
    return objs.map({ $0 })
  }
  
  func copy<T: NSManagedObject>(objects: [T]) -> [T] {
    return objects
  }
  
}

// MARK: Inserting

extension Transaction {
  
  func insert<T: NSManagedObject>() -> T {
    let entityName = NSStringFromClass(T)
    return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self.stack.rootContext!) as! T
  }
  
}

// MARK: Deleting

extension Transaction {
  
  func delete<T: NSManagedObject>(objects objs: T...) {
    
  }
  
  func delete<T: NSManagedObject>(objects: [T]) {
    
  }
  
}

