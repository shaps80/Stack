//
//  Query.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import Foundation
import CoreData


/**
 Defines a sort direction for better readability
 
 - Ascending:  Sort in ascending order
 - Descending: Sorts in descending order
 */
public enum SortDirection {
  case Ascending
  case Descending
}

/**
 Defines a result type for a Stack Query
 
 - ManagedObjects:   The query will return NSManagedObject's in its result
 - ManagedObjectIDs: The query will return NSManagedObjectID's in its result
 - Dictionaries:     The query will return dictionaries in its result
 */
public enum QueryResultType {
  case ManagedObjects
  case ManagedObjectIDs
  case Dictionaries
  
  /**
   A convenience function to convert a QueryResultType to an NSFetchRequestResultType
   
   - returns: The NSFetchRequestResultType
   */
  func toFetchRequestResultType() -> NSFetchRequestResultType {
    switch self {
    case .ManagedObjects:
      return .ManagedObjectResultType
    case .Dictionaries:
      return .DictionaryResultType
    case .ManagedObjectIDs:
      return .ManagedObjectIDResultType
    }
  }
}

/// Defines a type-safe Query for usage with Stack
public class Query<T: NSManagedObject>: CustomDebugStringConvertible, CustomStringConvertible {
  
  // MARK: Public Functions
  
  /**
  Set if, when the query is executed, property data is obtained from the persistent store.  If the value is set to false, the request will not obtain property information, but only information to identify each object (used to create NSManagedObjectIDs.)  If managed objects for these IDs are later faulted (as a result of attempting to access property values), they will incur subsequent access to the persistent store to obtain their property values.  Defaults to true.
  
  - parameter propertyValues: true if you want to include property values, false otherwise
  
  - returns: The modified query
  */
  public func include(propertyValues propertyValues: Bool) -> Query<T> {
    includesPropertyValues = propertyValues
    return self
  }
  
  /**
   Set whether or not to accommodate the currently unsaved changes in the NSManagedObjectContext.  When disabled, the query skips checking unsaved changes and only returns objects that matched the predicate in the persistent store.  Defaults to true
   
   - parameter pendingChanges: true if you want to include pending changes, false otherwise
   
   - returns: The modified query
   */
  public func include(pendingChanges pendingChanges: Bool) -> Query<T> {
    includesPendingChanges = pendingChanges
    return self
  }
  
  /**
   Set if the fetch request includes subentities.  If set to false, the query will fetch objects of exactly the entity type of the request;  if set to true, the request will include all subentities of the entity for the request.  Defaults to true
   
   - parameter subentities: true if you want to include sub-entities, false otherwise
   
   - returns: The modified query
   */
  public func include(subentities subentities: Bool) -> Query<T> {
    includesSubentities = subentities
    return self
  }
  
  /**
   Set the collection of either NSPropertyDescriptions or NSString property names that should be fetched. The collection may represent attributes, to-one relationships, or NSExpressionDescription.  If resultType == Dictionaries, the results of the fetch will be dictionaries containing key/value pairs where the key is the name of the specified property description.  If resultType == ManagedObjects, then NSExpressionDescription cannot be used, and the results are managed object faults partially pre-populated with the named properties
   
   - parameter properties: The properties to include
   
   - returns: The modified query
   */
  public func include(properties properties: [String]) -> Query<T> {
    includeProperties = properties
    return self
  }
  
  /**
   Set the collection of either NSPropertyDescriptions or NSString property names that should be fetched. The collection may represent attributes, to-one relationships, or NSExpressionDescription.  If resultType == Dictionaries, the results of the fetch will be dictionaries containing key/value pairs where the key is the name of the specified property description.  If resultType == ManagedObjects, then NSExpressionDescription cannot be used, and the results are managed object faults partially pre-populated with the named properties
   
   - parameter properties: The properties to include
   
   - returns: The modified query
   */
  public func include(descriptors descriptors: [NSPropertyDescription]) -> Query<T> {
    includeProperties = descriptors
    return self
  }
  
  /**
   Set an array of relationship keypaths to prefetch along with the entity for the query.  The array contains keypath strings in NSKeyValueCoding notation, as you would normally use with valueForKeyPath
   
   - parameter keyPaths: The relationship keyPaths to include
   
   - returns: The modified query
   */
  public func include(relationship keyPaths: [String]) -> Query<T> {
    includeRelationships = keyPaths
    return self
  }
  
  /**
   Appends a sort descriptor using the specified key and direction
   
   - parameter key:       The key to sort by
   - parameter direction: The sort direction. Defaults to .Ascending
   
   - returns: The modified query
   */
  public func sort(byKey key: String, direction: SortDirection = .Ascending) -> Query<T> {
    let sortDescriptor = NSSortDescriptor(key: key, ascending: direction == .Ascending)
    sortDescriptors.append(sortDescriptor)
    return self
  }
  
  /**
   Appends sort descriptors using the specified key/direction pairs
   
   - parameter keys: The key/direction pairs to sort by.
   
   - returns: The modified query
   */
  public func sort(byKeys keys: [String: SortDirection]) -> Query<T> {
    for (key, direction) in keys {
      let sortDescriptor = NSSortDescriptor(key: key, ascending: direction == .Ascending)
      sortDescriptors.append(sortDescriptor)
    }
    
    return self
  }
  
  /**
   Appends the specified sort descriptors to the query
   
   - parameter descriptors: The sort descriptors to append
   
   - returns: The modified query
   */
  public func sort(bySortDescriptors descriptors: [NSSortDescriptor]) -> Query<T> {
    sortDescriptors.appendContentsOf(descriptors)
    return self
  }
  
  /**
   Updates the predicate to apply for this query. Also Supports `pred1 && pred2` or `pred1 || pred2` -- negating the need for NSCompoundPredicate in many cases
   
   - parameter pred: The predicate to apply
   
   - returns: The modified query
   */
  public func filter(predicate pred: NSPredicate) -> Query<T> {
    self.predicate = pred
    return self
  }
  
  /**
   Updates the predicate to apply for this query
   
   - parameter format: The format string to use for this predicate
   - parameter args:   The arguments to be replaced in the format string
   
   - returns: The modified query
   */
  public func filter(format: String, _ args: AnyObject...) -> Query<T> {
    self.predicate = NSPredicate(format: format, argumentArray: args)
    return self
  }
  
  /**
   Sets whether or not to return results as a fault
   
   - parameter fault: Set to false to return results with their values pre-populated. Defaults to true
   
   - returns: The modified query
   */
  public func fault(fault: Bool) -> Query<T> {
    returnsObjectsAsFaults = fault
    return self
  }
  
  /**
   Sets whether or not to return distinct values for this query. Defaults to false
   
   - parameter distinct: This only applies when resultType == .Dictionaries
   
   - returns: The modified query
   */
  public func distinct(distinct: Bool) -> Query<T> {
    returnsDistinctResults = distinct
    return self
  }
  
  /**
   Updates the fetch batch offset for this query. Defaults to 0
   
   - parameter offset: The offset to apply
   
   - returns: The modified query
   */
  public func offset(offset: Int) -> Query<T> {
    fetchOffset = offset
    return self
  }
  
  /**
   Updates the fetch batch size for this query. Defaults to 0
   
   - parameter size: The size to apply
   
   - returns: The modified query
   */
  public func batch(size: Int) -> Query<T> {
    fetchBatchSize = size
    return self
  }
  
  /**
   Updates the batch batch limit for this query. Defaults to 0
   
   - parameter limit: The limit to apply
   
   - returns: The modified query
   */
  public func limit(limit: Int) -> Query<T> {
    fetchLimit = limit
    return self
  }
  
  public init() { }
  
  // MARK: Internal 
  
  /**
  This convenience initializer is used internally for setting up the query to perform fetches based on identifier
  
  - parameter key:        The identifier key
  - parameter identifier: The identifier value
  
  - returns: The configured query
  */
  convenience init<ID: StackManagedKey>(key: String, identifier: ID) {
    self.init()
    predicate = NSPredicate(format: "%K == %@", key, identifier)
  }

  /**
   This convenience initializer is used internally for setting up the query to perform fetches based on multiple identifiers
   
   - parameter key:         The identifier key
   - parameter identifiers: The identifier values
   
   - returns: The configured query
   */
  convenience init<IDs: StackManagedKey>(key: String, identifiers: [IDs]) {
    self.init()
    predicate = NSPredicate(format: "%K IN %@", key, identifiers)
  }
  
  /// Returns a print friendly description
  public var description: String {
    var description = ""
    
    description += "  class:\t\t\t\t\(NSStringFromClass(T))"
    description += "\n  filtering:\t\t\t\(predicate != nil ? "\(predicate)" : "none")"
    description += "\n  sorting:\t\t\t\(sortDescriptors.count > 0 ? "\(sortDescriptors)" : "none")"
    description += "\n  resultType:\t\t\(resultType)"
    
    return description
  }
  
  /// Returns a debug friendly description
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
  
  /// Get/set the predicate for this query
  private(set) var predicate: NSPredicate?
  
  /// Get/set the sortDescriptors for this query
  private(set) var sortDescriptors = [NSSortDescriptor]()
  
  /// Get/set the fetchBatchSize for this query. Defaults to 0
  private(set) var fetchBatchSize = 0
  
  /// Get/set the fetchOffset for this query. Defaults to 0
  private(set) var fetchOffset = 0
  
  /// Get/set the fetchLimit for this query. Defaults to 0
  private(set) var fetchLimit = 0
  
  /// Get/set whether or not this query should returns objects as faults. Defaults to true
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
  
  /// Get/set whether or not this query should return distint results. This only applies when resultType == .Dictionaries. Defaults to false
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
  
  /// Get/set if, when the query is executed, property data is obtained from the persistent store.  If the value is set to false, the request will not obtain property information, but only information to identify each object (used to create NSManagedObjectIDs.)  If managed objects for these IDs are later faulted (as a result of attempting to access property values), they will incur subsequent access to the persistent store to obtain their property values.  Defaults to true.
  private(set) var includesPropertyValues: Bool = true
  
  /// Get/set whether or not to accommodate the currently unsaved changes in the NSManagedObjectContext.  When disabled, the query skips checking unsaved changes and only returns objects that matched the predicate in the persistent store.  Defaults to true
  private(set) var includesPendingChanges: Bool = true
  
  /// Get/sets if the fetch request includes subentities.  If set to false, the query will fetch objects of exactly the entity type of the request;  if set to true, the request will include all subentities of the entity for the request.  Defaults to true
  private(set) var includesSubentities: Bool = true
  
  /// Get/set the collection of either NSPropertyDescriptions or NSString property names that should be fetched. The collection may represent attributes, to-one relationships, or NSExpressionDescription.  If resultType == Dictionaries, the results of the fetch will be dictionaries containing key/value pairs where the key is the name of the specified property description.  If resultType == ManagedObjects, then NSExpressionDescription cannot be used, and the results are managed object faults partially pre-populated with the named properties
  private(set) var includeProperties: [AnyObject]?
  
  /// Get/set an array of relationship keypaths to prefetch along with the entity for the query.  The array contains keypath strings in NSKeyValueCoding notation, as you would normally use with valueForKeyPath
  private(set) var includeRelationships: [String]?
  
  /// Get/set the result type you want from this query. Setting the value to .ManagedObjectIDs will demote any sort orderings to "best effort" hints if property values are not included in the request.
  public var resultType: QueryResultType = .ManagedObjects
  
  /**
   A convenience function for returns a configured NSFetchRequest based on this query
   
   - parameter entityName: The entity name to use for this request
   
   - returns: A newly configured NSFetchRequest
   */
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
  
}




