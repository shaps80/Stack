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

public final class Stack: CustomStringConvertible {
  
  public var description: String {
    return configuration.description
  }
  
  private static var stacks = { return [String: Stack]() }()
  
  private let coordinator: NSPersistentStoreCoordinator
  private let configuration: StackConfiguration
  
  internal lazy var rootContext: NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    context.persistentStoreCoordinator = self.coordinator
    return context
  }()
  
  public class func add(name: String, configure: ((_: StackConfiguration) -> ())?) {
    let config = StackConfiguration(name: name)
    configure?(config)
    
    let stack = Stack(config: config)
    stacks[name] = stack
  }
  
  func entityNameForManagedObjectClass(objectClass: AnyClass) -> String? {
    let entities = coordinator.managedObjectModel.entitiesByName.values
    
    for entity in entities {
      if entity.managedObjectClassName == NSStringFromClass(objectClass) {
        return entity.name
      }
    }
    
    return nil
  }
  
  public class func stack(named name: String) -> Stack? {
    guard let stack = stacks[name] else {
      if name != DefaultConfiguration.name {
        print("Stack: attempted to load a stack named '\(name)' that doesn't exist. Use Stack.add(name, config) first.")
      }
      return nil
    }
    
    return stack
  }
  
  private init(config: StackConfiguration) {
    let model = NSManagedObjectModel.mergedModelFromBundles(nil)
    coordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
    
    do {
      var storeType: String!
      
      switch config.persistenceType {
      case .Binary:
        storeType = NSBinaryStoreType
      case .MemoryOnly:
        storeType = NSInMemoryStoreType
      default:
        storeType = NSSQLiteStoreType
      }
      
      try coordinator.addPersistentStoreWithType(storeType, configuration: nil, URL: config.storeURL, options: config.storeOptions)
    } catch {
      print("Unable to add a persistent store for configuration: \(config)")
    }
    
    self.configuration = config
  }
  
}

// MARK: Default Stack

extension Stack {
  
  private static let name = "Default"
  
  public static func defaultStack() -> Stack {
    if let stack = Stack.stack(named: name) {
      return stack
    }
    
    let stack = Stack(config: DefaultConfiguration)
    stacks[name] = stack
    return stack
  }
  
  private static var DefaultConfiguration: StackConfiguration = {
    return StackConfiguration(name: name)
  }()
  
  public class func configureDefaults(configure: (_: StackConfiguration) -> ()) {
    let configuration = StackConfiguration(name: name)
    configure(configuration)
    DefaultConfiguration = configuration
  }
  
}

// MARK: Queries

extension Stack {
  
  public func fetch<T: NSManagedObject>(query: Query<T>) -> [T] {
    let entityName = NSStringFromClass(T)
    let request = NSFetchRequest(entityName: entityName)
    
    request.fetchBatchSize = query.fetchBatchSize
    request.fetchLimit = query.fetchLimit
    request.fetchOffset = query.fetchOffset
    request.sortDescriptors = query.sortDescriptors
    request.predicate = query.predicate
    request.returnsObjectsAsFaults = query.returnsObjectsAsFaults
    
    return [T]()
  }
  
  public func count<T: NSManagedObject>(_: (query: Query<T>) -> ()) -> Int {
    return 0
  }
  
  public func count<T: NSManagedObject>(query: Query<T>) -> Int {
    let _ = query
    let entityName = NSStringFromClass(T)
    let request = NSFetchRequest(entityName: entityName)
    
    request.predicate = query.predicate
    
    var error: NSError?
    return self.rootContext.countForFetchRequest(request, error: &error)
  }
  
  public func write(sync transaction: (transaction: Transaction) -> Void) {
    transaction(transaction: Transaction(stack: self, context: self.rootContext))
  }
  
  public func write(async transaction: (transaction: Transaction) -> Void, completion: (() -> Void)?) {
    transaction(transaction: Transaction(stack: self, context: self.rootContext))
    completion?()
  }
  
}





