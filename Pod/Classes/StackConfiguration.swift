//
//  StackConfiguration.swift
//  Stack
//
//  Created by Shaps Mohsenin on 26/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import CoreData

public enum StackPersistenceType {
  case SQLite
  case Binary
  case MemoryOnly
}

public enum StackType {
  case ParentChild
  case MainThreadOnly
  case ManualMerge
}

public final class StackConfiguration: CustomStringConvertible {
  
  public var description: String { return
      "  name:\t\t\t\(name)" +
      "\n  bundle:\t\t\(bundle.bundlePath)" +
      "\n  storeURL:\t\t\(storeURL)" +
      "\n  options:\t\t\(storeOptions)" +
      "\n  type:\t\t\t\(stackType)"
  }
  
  public private(set) var name: String
  public var persistenceType: StackPersistenceType = .SQLite
  public var stackType: StackType = .ParentChild {
    didSet {
      if stackType == .ManualMerge {
//        assertionFailure("This is not currently working!")
      }
    }
  }
  
  public lazy var storeOptions: [NSObject : AnyObject] = {
    return [ NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true ]
  }()
  
  public lazy var bundle: NSBundle = {
    return NSBundle.mainBundle()
  }()
  
  public lazy var storeURL: NSURL = {
    let documentsPath: String! = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first
    let path = documentsPath + "/" + self.name + ".sqlite"
    return NSURL(fileURLWithPath: path)
  }()
  
  init(name: String) {
    self.name = name
  }
  
}
