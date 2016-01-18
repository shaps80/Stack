
//
//  Query.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import Foundation
import CoreData

public final class Query<T: NSManagedObject> {
  
  private(set) var predicate: NSPredicate?
  private(set) var sortDescriptors: [NSSortDescriptor]
  private(set) var returnsObjectsAsFaults: Bool = true
  private(set) var fetchLimit: Int = 0
  private(set) var fetchOffset: Int
  private(set) var fetchBatchSize: Int
  internal var fetchRequest: NSFetchRequest
  
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
  
  public func filter(format: NSString, _ args: CVarArgType...) -> Query<T> {
    let query = self
    return query
  }
  
  public func filter(predicate pred: NSPredicate) -> Query<T> {
    self.predicate = pred
    return self
  }
  
  public func find(_:((key: String) -> (NSPredicate))) -> Query<T> {
    return self
  }
  
  public init() {
    self.sortDescriptors = [NSSortDescriptor]()
    self.fetchLimit = 0;
    self.fetchOffset = 0
    self.fetchBatchSize = 0
    
    let entityName = ""
    fetchRequest = NSFetchRequest(entityName: entityName)
  }
  
  public convenience init(objectID: NSManagedObjectID) {
    self.init()
    self.predicate = NSPredicate(format: "objectID == %@", objectID)
  }
  
  public convenience init(identifier: String) {
    self.init()
    self.predicate = NSPredicate(format: "identifier == %@", identifier)
  }
  
  public convenience init(key: String, value: String) {
    self.init()
    self.predicate = NSPredicate(format: "%@ == %@", key, value)
  }
  
}


