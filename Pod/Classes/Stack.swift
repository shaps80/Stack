//
//  Stack.swift
//  Stack
//
//  Created by Shaps Mohsenin on 13/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import CoreData

// MARK: Stack

private let StackThreadContextKey = "stack_context"

class StackContextHandler: NSObject {
  
  unowned var stack: Stack
  
  init(stack: Stack) {
    self.stack = stack
  }
  
  func contextDidSaveContext(note: NSNotification) {
    stack.contextDidSaveContext(note, contextHandler: self)
  }
  
}

public final class Stack: CustomStringConvertible, Readable {
  
  private var contextHandler: StackContextHandler?
  
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
    
    switch configuration.stackType {
    case .ParentChild:
      context.parentContext = mainThreadContext
    default:
      context.persistentStoreCoordinator = coordinator
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
    precondition(model != nil, "Stack: A valid NSManagedObjectModel must be provided!")
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
      
      let filename = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String ?? "Stack"
      let pathExtension = config.persistenceType == .SQLite ? ".sqlite" : ".bin"
      let path = NSURL(string: filename + pathExtension, relativeToURL: config.storeURL)
      try coordinator.addPersistentStoreWithType(storeType, configuration: nil, URL: path, options: config.storeOptions)
    } catch {
      print("Unable to add a persistent store for configuration: \(config)")
    }
    
    self.configuration = config
    
    if configuration.stackType == .ManualMerge {
      contextHandler = StackContextHandler(stack: self)
      NSNotificationCenter.defaultCenter().addObserver(contextHandler!, selector: "contextDidSaveContext:", name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
  }
  
  deinit {
    if configuration.stackType == .ManualMerge {
      NSNotificationCenter.defaultCenter().removeObserver(contextHandler!, name: NSManagedObjectContextDidSaveNotification, object: rootContext)
    }
  }
  
  func contextDidSaveContext(note: NSNotification, contextHandler: StackContextHandler) {
    if note.object === mainThreadContext {
      return
    }
    
    if let info = note.userInfo {
      let userInfo = NSDictionary(dictionary: info)
      
      if let updated = userInfo.objectForKey(NSUpdatedObjectsKey) as? Set<NSManagedObject> {
        for object in updated {
          do { try mainThreadContext.existingObjectWithID(object.objectID) } catch { }
        }
      }
    }

    dispatch_async(dispatch_get_main_queue()) { () -> Void in
      self.mainThreadContext.mergeChangesFromContextDidSaveNotification(note)
    }
  }
  
  public func write(transaction: (transaction: Transaction) throws -> Void, completion: ((NSError?) -> Void)?) {
    let block: () -> () = { [unowned self] in
      do {
        try transaction(transaction: Transaction(stack: self, context: self.currentThreadContext()))
        self.currentThreadContext().save(true, completion: completion)
      } catch {
        completion?(error as NSError)
      }
    }
    
    currentThreadContext().performBlockAndWait(block)
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




