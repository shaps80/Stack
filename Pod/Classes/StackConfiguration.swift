//
//  StackConfiguration.swift
//  Stack
//
//  Created by Shaps Mohsenin on 26/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import CoreData

/**
 Defines the type of persistence you want to support
 
 - SQLite:     Your Stack will be backed by an SQLite database
 - Binary:     Your Stack will be serialized to disk as a binary file
 - MemoryOnly: Your Stack will never be persisted to disk, and will only exist in memory
 */
public enum StackPersistenceType: String {
  case SQLite
  case Binary
  case MemoryOnly
}

/**
 Defines the type of setup you want for your NSManagedObjectContext's
 
 - ParentChild:    Your stack will use parent-child NSManagedObjectContext's (recommended for simplicity with some performance wins)
 - MainThreadOnly: Your stack will use ONLY a main queue context, dispatching to the main thread if necessary (optimal for simple UI only based apps)
 - ManualMerge:    Your stack will use background contexts, but handle merging manually (optimal for large data access)
 */
public enum StackType {
  case ParentChild
  case MainThreadOnly
  case ManualMerge
}


/// A Stack Configuration is used to setup and configure your Stack
public final class StackConfiguration: CustomStringConvertible {
  
  /// Returns a string representation of the current configuration
  public var description: String { return
      "  name:\t\t\t\(name)" +
      "\n  bundle:\t\t\(bundle.bundlePath)" +
      "\n  storeURL:\t\t\(storeURL)" +
      "\n  options:\t\t\(storeOptions)" +
      "\n  type:\t\t\t\(stackType)"
  }
  
  /// Returns the name that will be used for the Stack. Defaults to CFBundleName
  public private(set) var name: String
  
  /// Get/set the persistence type to use for your Stack. Defaults to .SQLite
  public var persistenceType: StackPersistenceType = .SQLite
  
  /// Get/set the context configuration to use for your Stack. Defaults to .ParentChild
  public var stackType: StackType = .ParentChild
  
  /// Get/set the options you want to use to configure your NSPersistentStore
  public lazy var storeOptions: [NSObject : AnyObject] = {
    return [
      NSMigratePersistentStoresAutomaticallyOption: true,
      NSInferMappingModelAutomaticallyOption: true
    ]
  }()
  
  /// Get/set the bundle where your model can be loaded from. Defaults to NSBundle.mainBundle()
  public lazy var bundle: NSBundle = {
    return NSBundle.mainBundle()
  }()
  
  /// Get/set the storeURL where your Stack will be stored. Defaults to $APP_DIR/Documents (Note: this does not include filename or extension)
  public lazy var storeURL: NSURL = {
    return NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!)
  }()
  
  /**
   Private: Initializes this configuration with the specified name
   
   - parameter name: The name to apply for this configuration. Will be used for your Stack name and filename.
   
   - returns: A new configuration instance
   */
  init(name: String) {
    self.name = name
  }
  
}
