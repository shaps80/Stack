
//
//  Readable.swift
//  Stack
//
//  Created by Shaps Mohsenin on 13/02/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import CoreData

extension Readable {
  
  /**
   Copies the specified object into the current thread's context and returns it to the caller
   
   - parameter object: The object to copy
   
   - returns: The newly copied object
   */
  public func copy<T: NSManagedObject>(object: T) -> T {
    let objects = copy([object]) as [T]
    return objects.first!
  }
  
  /**
   Copies the specified objects into the current thread's context and returns them to the caller
   
   - parameter objs: The objects to copy
   
   - returns: The newly copied objects
   */
  public func copy<T: NSManagedObject>(objects objs: T...) -> [T] {
    return copy(objs)
  }
  
  /**
   Copies the specified objects into the current thread's context and returns them to the caller
   
   - parameter objects: The objects to copy
   
   - returns: The newly copied objects
   */
  public func copy<T: NSManagedObject>(objects: [T]) -> [T] {
    var results = [T]()
    
    for object in objects {
      if object.managedObjectContext == _stack().currentThreadContext() {
        results.append(object)
      } else {
        if let obj = _stack().currentThreadContext().objectWithID(object.objectID) as? T {
          results.append(obj)
        }
      }
    }
    
    return results
  }
  
  /**
   Returns the number of results that would be returned if a fetch was performed using the specified query
   
   - parameter query: The query to perform
   
   - throws: An error will be thrown if the query cannot be performed
   
   - returns: The number of results
   */
  public func count<T: NSManagedObject>(query: Query<T>) throws -> Int {
    let request = try fetchRequest(query)
    var error: NSError?
    let count = _stack().currentThreadContext().countForFetchRequest(request, error: &error)
    
    if let error = error {
      throw StackError.FetchError(error)
    }
    
    return count
  }
  
  /**
   Performs a fetch using the specified query and returns the results to the caller
   
   - parameter query: The query to perform
   
   - throws: An eror will be thrown if the query cannot be performed
   
   - returns: The resulting objects
   */
  public func fetch<T: NSManagedObject>(query: Query<T>) throws -> [T] {
    let request = try fetchRequest(query)
    
    let stack = _stack()
    let context = stack.currentThreadContext()
    
    guard let results = try context.executeFetchRequest(request) as? [T] else {
      throw StackError.InvalidResultType(T.Type)
    }
    
    return results
  }
  
  /**
   Performs a fetch using the specified query and returns the first result
   
   - parameter query: The query to perform
   
   - throws: An error will be thrown is the query cannot be performed
   
   - returns: The resulting object or nil
   */
  public func fetch<T: NSManagedObject>(first query: Query<T>) throws -> T? {
    return try fetch(query).first
  }
  
  /**
   Performs a fetch using the specified query and returns the last result
   
   - parameter query: The query to perform
   
   - throws: An error will be thrown is the query cannot be performed
   
   - returns: The resulting object or nil
   */
  public func fetch<T: NSManagedObject>(last query: Query<T>) throws -> T? {
    return try fetch(query).first
  }
  
  /**
   Performs a fetch using the specified NSManagedObjectID
   
   - parameter objectID: The objectID to use for this fetch
   
   - throws: An error will be thrown if the query cannot be performed
   
   - returns: The resulting object or nil
   */
  public func fetch<T: NSManagedObject>(objectWithID objectID: NSManagedObjectID) throws -> T? {
    let stack = _stack()
    let context = stack.currentThreadContext()
    
    return try context.existingObjectWithID(objectID) as? T
  }
  
  /**
   A convenience method that converts this query into an NSFetchRequest
   
   - parameter query: The query to convert
   
   - throws: An error will be thrown is the entity name cannot be found or an entity couldn't be associated with the specified class (using generics)
   
   - returns: The resulting NSFetchRequest -- Note: this will not be configured
   */
  internal func fetchRequest<T: NSManagedObject>(query: Query<T>) throws -> NSFetchRequest {
    guard let entityName = _stack().entityNameForManagedObjectClass(T) else {
      throw StackError.EntityNameNotFoundForClass(T)
    }
    
    guard let request = query.fetchRequestForEntityNamed(entityName) else {
      throw StackError.EntityNotFoundInStack(_stack(), entityName)
    }
    
    return request
  }
  
}

