//
//  Stack.swift
//  Stack
//
//  Created by Shaps Mohsenin on 13/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import UIKit
import CoreData

public enum StackError: ErrorType {
  case EntityNameNotFoundForClass(AnyClass)
  case EntityNotFoundInStack(Stack, String)
  case InvalidResultType(AnyClass.Type)
}

// MARK: Stack

public final class Stack: CustomStringConvertible {
  
  public var description: String {
    return configuration.description
  }
  
  private static var stacks = { return [String: Stack]() }()
  
  private let coordinator: NSPersistentStoreCoordinator
  private let configuration: StackConfiguration
  
  private lazy var rootContext: NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    context.persistentStoreCoordinator = self.coordinator
    return context
  }()
  
  
  lazy var mainThreadContext: NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    context.parentContext = self.rootContext
    return context
  }()
  
  func currentThreadContext() -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    context.parentContext = self.mainThreadContext
    return context
  }
  
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
    
    configuration.storeOptions = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
    configuration.storeURL = NSURL(string: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!)!
    configuration.persistenceType = .MemoryOnly
    configuration.stackType = .ParentChild
    configuration.name = "My Stack" // becomes ./$STORE_URL/$NAME.sqlite
    
    configure(configuration)
    DefaultConfiguration = configuration
  }
  
}

// MARK: Queries -- Makes Transaction's and Stack itself support querying

protocol StackSupport {
  func _stack() -> Stack
}

extension Stack: ReadSupport, StackSupport {
  
  func _stack() -> Stack {
    return self
  }
  
  public func write(sync transaction: (transaction: Transaction) -> Void) {
    transaction(transaction: Transaction(stack: self, context: self.rootContext))
  }
  
  public func write(async transaction: (transaction: Transaction) -> Void, completion: (() -> Void)?) {
    transaction(transaction: Transaction(stack: self, context: self.rootContext))
    completion?()
  }
  
}

extension Transaction: ReadSupport, StackSupport {
  
  func _stack() -> Stack {
    return self.stack
  }
  
}

public protocol ReadSupport {
  
  func count<T: NSManagedObject>(query: Query<T>) throws -> Int
  
  func fetch<T: NSManagedObject>(query: Query<T>) throws -> [T]
  func fetch<T: NSManagedObject>(first query: Query<T>) throws -> T?
  func fetch<T: NSManagedObject>(last query: Query<T>) throws -> T?
  
}

extension ReadSupport {
 
  func _stack() -> Stack { return Stack.defaultStack() }
  
  public func fetch<T: NSManagedObject>(query: Query<T>) throws -> [T] {
    guard let entityName = _stack().entityNameForManagedObjectClass(T) else {
      throw StackError.EntityNameNotFoundForClass(T)
    }
    
    guard let request = query.fetchRequestForEntityNamed(entityName) else {
      throw StackError.EntityNotFoundInStack(_stack(), entityName)
    }
    
    guard let results = try _stack().currentThreadContext().executeFetchRequest(request) as? [T] else {
      throw StackError.InvalidResultType(T.Type)
    }
    
    return results
  }
  
  public func fetch<T: NSManagedObject>(first query: Query<T>) throws -> T? {
    return try fetch(query).first
  }
  
  public func fetch<T: NSManagedObject>(last query: Query<T>) throws -> T? {
    return try fetch(query).first
  }
  
  public func count<T: NSManagedObject>(query: Query<T>) throws -> Int {
    guard let entityName = _stack().entityNameForManagedObjectClass(T) else {
      throw StackError.EntityNameNotFoundForClass(T)
    }
    
    guard let request = query.fetchRequestForEntityNamed(entityName) else {
      throw StackError.EntityNotFoundInStack(_stack(), entityName)
    }
    
    var error: NSError?
    return _stack().currentThreadContext().countForFetchRequest(request, error: &error)
  }
  
}

