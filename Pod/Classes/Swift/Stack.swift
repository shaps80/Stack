//
//  Stack.swift
//  Stack
//
//  Created by Shaps Mohsenin on 13/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import UIKit
import CoreData

// MARK: Stack

final class Stack {
  
  static var stacks = { return Dictionary<String, Stack>() }()
  
  private let name: String
  private let coordinator: NSPersistentStoreCoordinator
  internal let rootContext: NSManagedObjectContext?
  
  class func register(stack: Stack) {
    stacks[stack.name] = stack
  }
  
  class func stack(named name: String) -> Stack? {
    return stacks[name]
  }
  
  private init(name: String, url: NSURL) {
    let model = NSManagedObjectModel.mergedModelFromBundles(nil)
    coordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
    
    do {
      try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
    } catch {
      print("Unable to add a persistent store: \(name)")
    }

    self.rootContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    self.rootContext!.persistentStoreCoordinator = coordinator
    self.name = name
  }
  
  internal required init(name: String) {
    let model = NSManagedObjectModel.mergedModelFromBundles(nil)
    self.coordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
    self.rootContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    self.rootContext!.persistentStoreCoordinator = coordinator
    self.name = name;
  }
  
}

// MARK: Default Stacks

extension Stack {
  
  static func defaultStack() -> Stack {
    var name = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as! String
    name = name.stringByAppendingString("-Memory")
    
    if let stack = Stack.stack(named: name) {
      return stack
    }
    
    let documentsPath: String! = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first
    let path = documentsPath + "/" + name + ".sqlite"
    let url = NSURL(fileURLWithPath: path)
    let stack = Stack(name: name, url: url)
    
    Stack.register(stack)
    
    return stack
  }
  
  static func memoryStack() -> Stack {
    var name = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as! String
    name = name.stringByAppendingString("-Memory")
    
    if let stack = Stack.stack(named: name) {
      return stack
    }
    
    let stack = Stack(name: name)
    Stack.register(stack)
    
    return stack
  }
  
}

// MARK: Queries

extension Stack {
  
  func fetch<T: NSManagedObject>(query: Query<T>) -> [T]? {
    let entityName = NSStringFromClass(T)
    let request = NSFetchRequest(entityName: entityName)
    
    request.fetchBatchSize = query.fetchBatchSize
    request.fetchLimit = query.fetchLimit
    request.fetchOffset = query.fetchOffset
    request.sortDescriptors = query.sortDescriptors
    request.predicate = query.predicate
    request.returnsObjectsAsFaults = query.returnsObjectsAsFaults
    
//    do {
//      if let objects = try self.rootContext?.executeFetchRequest(request) as? [T] {
//        return objects
//      }
//    } catch {
//      print("An error occured while attempting to fetch objects: \(request)")
//    }
    
    return nil
  }
  
  func fetch<T: NSManagedObject>(firstInQuery query: Query<T>) -> T? {
    if let objects: [T] = self.fetch(query) {
      return objects.first
    }
    
    return nil
  }
  
  func count<T: NSManagedObject>(query: Query<T>) -> Int {
    let _ = query
    let entityName = NSStringFromClass(T)
    let request = NSFetchRequest(entityName: entityName)
    
    request.predicate = query.predicate
    
    var error: NSError?
    let count = self.rootContext?.countForFetchRequest(request, error: &error)
    return count!
  }
  
}

// MARK: Transactions

extension Stack {
  
  func write(sync transaction: (transaction: Transaction) -> Void) {
    if let _ = self.rootContext {
      transaction(transaction: Transaction(stack: self, context: self.rootContext!))
      
//      do {
//        try context.save()
//      } catch { }
    }
  }
  
  func write(async transaction: (transaction: Transaction) -> Void, completion: () -> Void) {

    completion()
  }
  
}




