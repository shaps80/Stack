/*
  Copyright © 2015 Shaps Mohsenin. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY SHAPS MOHSENIN `AS IS' AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
  EVENT SHALL THE APP BUSINESS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CoreData

private let StackThreadContextKey = "stack_context"

/// This class is responsible for listening for NSNotification's on context changes. It exists purely as a convenience, so that we don't have to subclass NSObject on our Stack!
class StackContextHandler: NSObject {
  
  unowned var stack: Stack
  
  init(stack: Stack) {
    self.stack = stack
  }
  
  // Called when an NSManagedObjectContext posts changes
  func contextDidSaveContext(note: NSNotification) {
    stack.contextDidSaveContext(note, contextHandler: self)
  }
  
}

/// A Stack is a CoreData wrapper that provides a type-safe implementation for reading and writing to CoreData
public final class Stack: CustomStringConvertible, Readable {
  
  /// The context handler that will listen for notifications. Only used when stackType = .ManualMerge
  private var contextHandler: StackContextHandler?
  
  /// Returns a string representation of the Stack's configuration
  public var description: String {
    return configuration.description
  }
  
  /// Holds onto the various Stacks in your application (1 or more)
  private static var stacks = { return [String: Stack]() }()
  
  /// The persistent coordinator associated with this stack
  private let coordinator: NSPersistentStoreCoordinator
  
  /// The configuration associated with this stack
  private let configuration: StackConfiguration
  
  /// The root context. Used only when stackType != .ManualMerge
  lazy var rootContext: NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    context.persistentStoreCoordinator = self.coordinator
    return context
  }()
  
  /// The main thread context.
  private lazy var mainContext: NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    if self.configuration.stackType == .ManualMerge {
      context.persistentStoreCoordinator = self.coordinator
    } else {
      context.parentContext = self.rootContext
    }
    
    return context
  }()
  
  /**
   Returns a context associated with the current thread. This function may return an existing context, however if none exist, it will create one, add it to the threadDictionary and return it
   
   - returns: An NSManagedObjectContext that can be used on the current thread
   */
  func currentThreadContext() -> NSManagedObjectContext {
    if NSThread.isMainThread() || configuration.stackType == .MainThreadOnly {
      return mainContext
    }
    
    if let context = NSThread.currentThread().threadDictionary[StackThreadContextKey] as? NSManagedObjectContext {
      return context
    }
    
    let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    
    switch configuration.stackType {
    case .ParentChild:
      context.parentContext = mainContext
    default:
      context.persistentStoreCoordinator = coordinator
    }
    
    NSThread.currentThread().threadDictionary[StackThreadContextKey] = context
    return context
  }
  
  /**
   Adds a new Stack
   
   - parameter name:      The name for this stack. Must be unique!
   - parameter configure: The configuration to apply to this Stack
   */
  public class func add(name: String, configure: ((_: StackConfiguration) -> ())?) {
    let config = StackConfiguration(name: name)
    configure?(config)
    
    let stack = Stack(config: config)
    stacks[name] = stack
  }
  
  /**
   Returns the entity name associated with the specified NSManagedObject class
   
   - parameter objectClass: The object
   
   - returns: The entity name for this managedObject class or nil if not found
   */
  func entityNameForManagedObjectClass(managedObjectClass: AnyClass) -> String? {
    let entities = coordinator.managedObjectModel.entitiesByName.values
    
    for entity in entities {
      if entity.managedObjectClassName == NSStringFromClass(managedObjectClass) {
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
    self.configuration = config
    
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
      
      let filename = config.name
      let pathExtension = config.persistenceType == .SQLite ? ".sqlite" : ".bin"
      let path = NSURL(string: filename + pathExtension, relativeToURL: config.storeURL)
      try coordinator.addPersistentStoreWithType(storeType, configuration: nil, URL: path, options: config.storeOptions)
    } catch {
      print("Unable to add a persistent store for configuration: \(config)")
    }
    
    if config.stackType == .ManualMerge {
      contextHandler = StackContextHandler(stack: self)
      NSNotificationCenter.defaultCenter().addObserver(contextHandler!, selector: #selector(StackContextHandler.contextDidSaveContext(_:)), name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
  }
  
  deinit {
    if configuration.stackType == .ManualMerge {
      NSNotificationCenter.defaultCenter().removeObserver(contextHandler!, name: NSManagedObjectContextDidSaveNotification, object: rootContext)
    }
  }
  
  func contextDidSaveContext(note: NSNotification, contextHandler: StackContextHandler) {
    if note.object === mainContext {
      return
    }
    
    if let info = note.userInfo {
      let userInfo = NSDictionary(dictionary: info)
      
      if let updated = userInfo.objectForKey(NSUpdatedObjectsKey) as? Set<NSManagedObject> {
        for object in updated {
          do { try mainContext.existingObjectWithID(object.objectID) } catch { }
        }
      }
    }

    dispatch_async(dispatch_get_main_queue()) { () -> Void in
      self.mainContext.mergeChangesFromContextDidSaveNotification(note)
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

// MARK: OSX Additions

extension Stack {
  
#if os(OSX)
  
  /**
  Provided as a convenience for OSX only -- since a lot of bindings rely on having access to an NSManagedObjectContext
  
  - returns: The NSManagedObjectContext for use ONLY on the main queue
  */
  public func mainThreadContext() -> NSManagedObjectContext {
    return mainContext
  }
#endif
  
}

// MARK: Default Stack

extension Stack {
  
  /// Returns the default Stack name
  private static let DefaultName = "Default"
  
  /**
   Returns a default Stack instance that uses the default configuration. You can modify the configuration by calling Stack.configureDefaults() early in your applications lifecycle
   
   - returns: The default Stack
   */
  public static func defaultStack() -> Stack {
    if let stack = Stack.stack(named: DefaultName) {
      return stack
    }
    
    let stack = Stack(config: DefaultConfiguration)
    stacks[DefaultName] = stack
    return stack
  }
  
  /// Private: Returns the default Stack configuration
  private static var DefaultConfiguration: StackConfiguration = {
    return StackConfiguration(name: DefaultName)
  }()
  
  /**
   Provides a convenience function for configuring the default Stack before its initialized
   
   - parameter configure: The configuration to apply
   */
  public class func configureDefaults(configure: (_: StackConfiguration) -> ()) {
    let configuration = StackConfiguration(name: DefaultName)
    configure(configuration)
    DefaultConfiguration = configuration
  }
  
  
}




