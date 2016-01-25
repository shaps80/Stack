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

private let StackThreadContextKey = "stack_context"

class StackContextHandler: NSObject {
  
  unowned var context: NSManagedObjectContext
  unowned var stack: Stack
  
  init(stack: Stack, context: NSManagedObjectContext) {
    self.context = context
    self.stack = stack
    super.init()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSaveContext:", name: NSManagedObjectContextDidSaveNotification, object: context)
  }
  
  func contextDidSaveContext(note: NSNotification) {
    stack.contextDidSaveContext(note, contextHandler: self)
    NSNotificationCenter.defaultCenter().removeObserver(self, name: "contextDidSaveContext:", object: context)
  }
  
  override func isEqual(object: AnyObject?) -> Bool {
    if let handler = object as? StackContextHandler {
      return handler.context == self.context && handler.stack.configuration.name == self.stack.configuration.name
    }
    
    return false
  }
  
}

func ==(lhs: StackContextHandler, rhs: StackContextHandler) -> Bool {
  return lhs.isEqual(rhs)
}

public final class Stack: CustomStringConvertible, Readable {
  
//  private var contextHandler: StackContextHandler?
  private var contextHandlers = [StackContextHandler]()
  
  public var description: String {
    return configuration.description
  }
  
  private static var stacks = { return [String: Stack]() }()
  
  private let coordinator: NSPersistentStoreCoordinator
  private let configuration: StackConfiguration
  
  lazy var rootContext: NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    context.persistentStoreCoordinator = self.coordinator
    return context
  }()
  
  
  private lazy var mainThreadContext: NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    
    if self.configuration.stackType == .ManualMerge {
      context.persistentStoreCoordinator = self.coordinator
    } else {
      context.parentContext = self.rootContext
    }
    
    return context
  }()
  
  func currentThreadContext() -> NSManagedObjectContext {
    if NSThread.isMainThread() || configuration.stackType == .MainThreadOnly {
      return mainThreadContext
    }
    
    if let context = NSThread.currentThread().threadDictionary[StackThreadContextKey] as? NSManagedObjectContext {
      return context
    }
    
    let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    
    if configuration.stackType != .ManualMerge {
      context.parentContext = mainThreadContext
    } else {
      context.persistentStoreCoordinator = coordinator
      contextHandlers.append(StackContextHandler(stack: self, context: context))
    }
    
    NSThread.currentThread().threadDictionary[StackThreadContextKey] = context
    
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
  
  func contextDidSaveContext(note: NSNotification, contextHandler: StackContextHandler) {
    if let info = note.userInfo {
      let userInfo = NSDictionary(dictionary: info)
      
      if let updated = userInfo.objectForKey(NSUpdatedObjectsKey) as? Set<NSManagedObject> {
        for object in updated {
          do { try mainThreadContext.existingObjectWithID(object.objectID) } catch { }
//          let mainThreadObject = mainThreadContext.objectWithID(object.objectID)
//          mainThreadObject.willAccessValueForKey(nil)
        }
      }
    }
    
//    contextHandlers.removeAtIndex(contextHandlers.indexOf(contextHandler)!)
    
    dispatch_async(dispatch_get_main_queue()) { () -> Void in
     self.mainThreadContext.mergeChangesFromContextDidSaveNotification(note)
    }
  }
  
  public func write(sync transaction: (transaction: Transaction) -> Void) {
    let context = currentThreadContext()

    context.performBlockAndWait({ [unowned self, context] () -> Void in
      transaction(transaction: Transaction(stack: self, context: context))
      context.save(true, completion: { (result) -> () in
        if case let NSManagedObjectContext.SaveResult.Failed(error) = result {
          print("Stack: Write failed -- \(error)")
        }
      })
    })
  }
  
  public func write(async transaction: (transaction: Transaction) -> Void, completion: (() -> Void)?) {
    let context = currentThreadContext()
    
    context.performBlock({ [unowned self, context] () -> Void in
      transaction(transaction: Transaction(stack: self, context: context))
      context.save(false, completion: { (result) -> () in
        if case let NSManagedObjectContext.SaveResult.Failed(error) = result {
          print("Stack: Write failed -- \(error)")
        }
        
        completion?()
      })
    })
  }
}

// MARK: Default Stack

extension Stack {
  
  private static let DefaultName = "Default"
  
  public static func defaultStack() -> Stack {
    if let stack = Stack.stack(named: DefaultName) {
      return stack
    }
    
    let stack = Stack(config: DefaultConfiguration)
    stacks[DefaultName] = stack
    return stack
  }
  
  private static var DefaultConfiguration: StackConfiguration = {
    return StackConfiguration(name: DefaultName)
  }()
  
  public class func configureDefaults(configure: (_: StackConfiguration) -> ()) {
    let configuration = StackConfiguration(name: DefaultName)
    configure(configuration)
    DefaultConfiguration = configuration
  }
  
  
}




