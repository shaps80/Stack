//
//  NSFetchedResultsController+Stack.swift
//  Stack
//
//  Created by Shaps Mohsenin on 26/11/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import CoreData

public protocol EntityDescriptor: NSObjectProtocol {
  static func entityName() -> String
  static func primaryKey() -> (String, Any.Type)
}

extension NSManagedObject: EntityDescriptor {
  
  public class func entityName() -> String {
    return NSStringFromClass(self)
  }
  
  public class func primaryKey() -> (String, Any.Type) {
    return ("identifier", String.self)
  }
  
}

