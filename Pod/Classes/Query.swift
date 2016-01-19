
//
//  Query.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import Foundation
import CoreData

public class Query<T: NSManagedObject> {
  
  private(set) var predicate: NSPredicate? {
    get {
      return self.predicate
    }
    set {
      if predicate == nil {
        self.predicate = newValue
        return
      }
      
      print("Query: The predicate can only be set once.")
    }
  }
  
  private(set) var sortDescriptors = [NSSortDescriptor]()
  private(set) var returnsObjectsAsFaults: Bool = true
  private(set) var fetchBatchSize: Int = 0
  private(set) var fetchOffset: Int = 0
  private(set) var fetchLimit: Int?
  
  func fetchRequestForEntityNamed(entityName: String) -> NSFetchRequest? {
    let request = NSFetchRequest(entityName: entityName)
    
    request.sortDescriptors = sortDescriptors
    request.predicate = predicate
    request.returnsObjectsAsFaults = returnsObjectsAsFaults
    request.fetchBatchSize = fetchBatchSize
    request.fetchOffset = fetchOffset
    
    if let limit = fetchLimit {
      request.fetchLimit = limit
    }
    
    return request
  }
  
  public func limit(limit: Int) -> Query<T> {
    fetchLimit = limit
    return self
  }
  
  public func fault(fault: Bool) -> Query<T> {
    returnsObjectsAsFaults = fault
    return self
  }
  
  public func offset(offset: Int) -> Query<T> {
    fetchOffset = offset
    return self
  }
  
  public func batch(size: Int) -> Query<T> {
    fetchBatchSize = size
    return self
  }
  
  public func sort(byKey key: String, ascending: Bool) -> Query<T> {
    let sortDescriptor = NSSortDescriptor(key: key, ascending: ascending)
    sortDescriptors.append(sortDescriptor)
    return self
  }
  
  public func sort(bySortDescriptors descriptors: [NSSortDescriptor]) -> Query<T> {
    sortDescriptors.appendContentsOf(descriptors)
    return self
  }

  public func filter(format: String, _ arguments: CVarArgType...) -> Query<T> {
    assertionFailure("Not Implemented")
    return self
  }
  
  public func filter(predicate pred: NSPredicate) -> Query<T> {
    self.predicate = pred
    return self
  }
  
  public convenience init(objectID: NSManagedObjectID) {
    self.init()
    predicate = NSPredicate(format: "objectID == %@", objectID)
  }
  
  public convenience init(key: String, identifier: String) {
    self.init()
    predicate = NSPredicate(format: "@K == %@", key, identifier)
  }
  
  public init() { }
  
}

public func && (left: NSPredicate, right: NSPredicate) -> NSPredicate {
  return NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [left, right])
}

public func || (left: NSPredicate, right: NSPredicate) -> NSPredicate {
  return NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: [left, right])
}



