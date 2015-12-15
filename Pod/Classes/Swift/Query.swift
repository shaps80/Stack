
//
//  Query.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import Foundation
import CoreData

final class Query<T: NSManagedObject> {
  
  private(set) var predicate: NSPredicate?
  private(set) var sortDescriptors: [NSSortDescriptor]
  private(set) var returnsObjectsAsFaults: Bool = true
  private(set) var fetchLimit: Int = 0
  private(set) var fetchOffset: Int
  private(set) var fetchBatchSize: Int
  internal var fetchRequest: NSFetchRequest
  
  func limit(limit: Int) -> Query<T> {
    fetchLimit = limit
    return self
  }
  
  func fault(fault: Bool) -> Query<T> {
    returnsObjectsAsFaults = fault
    return self
  }
  
  func offset(offset: Int) -> Query<T> {
    fetchOffset = offset
    return self
  }
  
  func batch(size: Int) -> Query<T> {
    fetchBatchSize = size
    return self
  }
  
  func sort(key: String, ascending: Bool) -> Query<T> {
    let sortDescriptor = NSSortDescriptor(key: key, ascending: ascending)
    sortDescriptors.append(sortDescriptor)
    return self
  }
  
  func filter(format fmt: String...) -> Query<T> {
    let query = self
    return query
  }
  
  func filter(predicate pred: NSPredicate) -> Query<T> {
    self.predicate = pred
    return self
  }
  
  init() {
    self.sortDescriptors = Array<NSSortDescriptor>()
    self.fetchLimit = 0;
    self.fetchOffset = 0
    self.fetchBatchSize = 0
    
    let entityName = ""
    fetchRequest = NSFetchRequest(entityName: entityName)
  }
  
  convenience init(objectID: NSManagedObjectID) {
    self.init()
    self.predicate = NSPredicate(format: "objectID == %@", objectID)
  }
  
  convenience init(identifier: NSObject) {
    self.init()
    self.predicate = NSPredicate(format: "identifier == %@", identifier)
  }
  
  convenience init(key: NSString, value: NSString) {
    self.init()
    self.predicate = NSPredicate(format: "%@ == %@", key, value)
  }
  
}


