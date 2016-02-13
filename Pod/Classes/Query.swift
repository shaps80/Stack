
//
//  Query.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import Foundation
import CoreData

public enum SortDirection {
  case Ascending
  case Descending
}

public class Query<T: NSManagedObject>: CustomDebugStringConvertible, CustomStringConvertible {
  
  public var description: String {
    var description = ""
    
    description += "  class:\t\t\t\t\(NSStringFromClass(T))"
    description += "\n  filtering:\t\t\t\(predicate != nil ? "\(predicate)" : "none")"
    description += "\n  sorting:\t\t\t\(sortDescriptors.count > 0 ? "\(sortDescriptors)" : "none")"
    description += "\n  resultType:\t\t\(resultType)"
    
    return description
  }
  
  public var debugDescription: String {
    var description = self.description + "\n"
    
    description += "\n  size:\t\t\t\t\(fetchBatchSize)"
    description += "\n  offset:\t\t\t\(fetchOffset)"
    description += "\n  limit:\t\t\t\t\(fetchLimit)"
    description += "\n"
    description += "\n  faulting:\t\t\t\(_returnsObjectsAsFaults == true && resultType == .ManagedObjectIDs ? "false (resultType == .ManagedObjectIDs)" : "\(returnsObjectsAsFaults)")"
    description += "\n  distinct:\t\t\t\(_returnsDistinctResults == true && resultType != .Dictionaries ? "false (resultType != .Dictionaries)" : "\(returnsDistinctResults)")"
    description += "\n"
    description += "\n  inc properties:\t\(includeProperties)"
    description += "\n  inc values:\t\t\(includesPropertyValues)"
    description += "\n  inc pending:\t\t\(includesPendingChanges)"
    description += "\n  inc relations:\t\t\(includeRelationships)"
    description += "\n  inc sub-entities:\t\(includesSubentities)"
    
    return description
  }
  
  private(set) var predicate: NSPredicate?
  private(set) var sortDescriptors = [NSSortDescriptor]()
  
  private(set) var fetchBatchSize = 0
  private(set) var fetchOffset = 0
  private(set) var fetchLimit = 0

  private var _returnsObjectsAsFaults = true
  private(set) var returnsObjectsAsFaults: Bool {
    set { _returnsObjectsAsFaults = newValue }
    get {
      if _returnsObjectsAsFaults == true && resultType == .ManagedObjectIDs {
        return false
      }
        
      return _returnsObjectsAsFaults
    }
  }

  private var _returnsDistinctResults = false
  private(set) var returnsDistinctResults: Bool {
    set { _returnsDistinctResults = newValue }
    get {
      if _returnsDistinctResults == true && resultType != .Dictionaries {
        return false
      }
      
      return _returnsDistinctResults
    }
  }
  
  private(set) var includesPropertyValues: Bool = true
  private(set) var includesPendingChanges: Bool = true
  private(set) var includesSubentities: Bool = true
  private(set) var includeProperties: [AnyObject]?
  private(set) var includeRelationships: [String]?
  
  public var resultType: QueryResultType = .ManagedObjects
  
  func fetchRequestForEntityNamed(entityName: String) -> NSFetchRequest? {
    let request = NSFetchRequest(entityName: entityName)
    
    request.predicate = predicate
    request.sortDescriptors = sortDescriptors
    
    request.fetchBatchSize = fetchBatchSize
    request.fetchOffset = fetchOffset
    request.fetchLimit = fetchLimit
  
    request.returnsObjectsAsFaults = returnsObjectsAsFaults
    request.returnsDistinctResults = returnsDistinctResults
    
    request.includesPropertyValues = includesPropertyValues
    request.includesPendingChanges = includesPendingChanges
    request.includesSubentities = includesSubentities
    
    request.propertiesToFetch = includeProperties
    request.relationshipKeyPathsForPrefetching = includeRelationships
    
    request.resultType = resultType.toFetchRequestResultType()
    
    return request
  }
  
  public func include(propertyValues propertyValues: Bool) -> Query<T> {
    includesPropertyValues = propertyValues
    return self
  }
  
  public func include(pendingChanges pendingChanges: Bool) -> Query<T> {
    includesPendingChanges = pendingChanges
    return self
  }
  
  public func include(subentities subentities: Bool) -> Query<T> {
    includesSubentities = subentities
    return self
  }
  
  public func include(properties properties: String...) -> Query<T> {
    includeProperties = properties
    return self
  }
  
  public func include(properties properties: [String]) -> Query<T> {
    includeProperties = properties
    return self
  }
  
  public func include(descriptors descriptors: [NSPropertyDescription]) -> Query<T> {
    includeProperties = descriptors
    return self
  }
  
  public func include(relationships keyPaths: String...) -> Query<T> {
    includeRelationships = keyPaths
    return self
  }
  
  public func include(relationships keyPaths: [String]) -> Query<T> {
    includeRelationships = keyPaths
    return self
  }
  
  public func limit(limit: Int) -> Query<T> {
    fetchLimit = limit
    return self
  }
  
  public func fault(fault: Bool) -> Query<T> {
    returnsObjectsAsFaults = fault
    return self
  }
  
  public func distinct(distinct: Bool) -> Query<T> {
    returnsDistinctResults = distinct
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
  
  public func sort(byKey key: String, direction: SortDirection) -> Query<T> {
    let sortDescriptor = NSSortDescriptor(key: key, ascending: direction == .Ascending)
    sortDescriptors.append(sortDescriptor)
    return self
  }
  
  public func sort(byKeys keys: [String: SortDirection]) -> Query<T> {
    for (key, direction) in keys {
      let sortDescriptor = NSSortDescriptor(key: key, ascending: direction == .Ascending)
      sortDescriptors.append(sortDescriptor)
    }
    
    return self
  }
  
  public func sort(bySortDescriptors descriptors: [NSSortDescriptor]) -> Query<T> {
    sortDescriptors.appendContentsOf(descriptors)
    return self
  }
  
  public func filter(predicate pred: NSPredicate) -> Query<T> {
    self.predicate = pred
    return self
  }
  
  public func filter(format: String, _ args: AnyObject...) -> Query<T> {
    self.predicate = NSPredicate(format: format, argumentArray: args)
    return self
  }
    
  public convenience init<ID: StackManagedKey>(key: String, identifier: ID) {
    self.init()
    predicate = NSPredicate(format: "%K == %@", key, identifier)
  }
  
  public convenience init<IDs: StackManagedKey>(key: String, identifiers: [IDs]) {
    self.init()
    predicate = NSPredicate(format: "%K IN %@", key, identifiers)
  }
  
  public init() { }
  
}

public func && (left: NSPredicate, right: NSPredicate) -> NSPredicate {
  return NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [left, right])
}

public func || (left: NSPredicate, right: NSPredicate) -> NSPredicate {
  return NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: [left, right])
}



