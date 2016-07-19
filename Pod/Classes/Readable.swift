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

extension Readable {
  
  /**
   Copies the specified object into the current thread's context and returns it to the caller
   
   - parameter object: The object to copy
   
   - returns: The newly copied object
   */
  public func copy<T: NSManagedObject>(object: T) -> T {
    let objects = copy(objects: [object]) as [T]
    return objects.first!
  }
  
  /**
   Copies the specified objects into the current thread's context and returns them to the caller
   
   - parameter objs: The objects to copy
   
   - returns: The newly copied objects
   */
  public func copy<T: NSManagedObject>(objects objs: T...) -> [T] {
    return copy(objects: objs)
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
        if let obj = _stack().currentThreadContext().object(with: object.objectID) as? T {
          results.append(obj)
        }
      }
    }
    
    return results
  }
  
  /**
   Returns the number of results that would be returned if a fe
   tch was performed using the specified query
   
   - parameter query: The query to perform
   
   - throws: An error will be thrown if the query cannot be performed
   
   - returns: The number of results
   */
  public func count<T: NSManagedObject>(query: Query<T>) throws -> Int {
    let request = try fetchRequest(query: query)
    var error: NSError?
    let count = try _stack().currentThreadContext().count(for: request)
    
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
    let request = try fetchRequest(query: query)
    
    let stack = _stack()
    let context = stack.currentThreadContext()
    
    guard let results = try context.fetch(request) as? [T] else {
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
    return try fetch(query: query).first
  }
  
  /**
   Performs a fetch using the specified query and returns the last result
   
   - parameter query: The query to perform
   
   - throws: An error will be thrown is the query cannot be performed
   
   - returns: The resulting object or nil
   */
  public func fetch<T: NSManagedObject>(last query: Query<T>) throws -> T? {
    return try fetch(query: query).last
  }
  
  /**
   A convenience method that converts this query into an NSFetchRequest
   
   - parameter query: The query to convert
   
   - throws: An error will be thrown is the entity name cannot be found or an entity couldn't be associated with the specified class (using generics)
   
   - returns: The resulting NSFetchRequest -- Note: this will not be configured
   */
  internal func fetchRequest<T: NSManagedObject>(query: Query<T>) throws -> NSFetchRequest<NSManagedObject> {
    guard let entityName = _stack().entityNameForManagedObjectClass(T) else {
      throw StackError.EntityNameNotFoundForClass(T)
    }
    
    guard let request = query.fetchRequestForEntityNamed(entityName: entityName) else {
      throw StackError.EntityNotFoundInStack(_stack(), entityName)
    }
    
    return request
  }
  
}

