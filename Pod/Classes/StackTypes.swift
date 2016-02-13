//
//  StackTypes.swift
//  Stack
//
//  Created by Shaps Mohsenin on 19/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import CoreData

/**
 *  Provides a protocol for any class that supports Reading from a Stack
 */
public protocol Readable: StackSupport {
  
  /**
   Copies the specified object into the current thread's context and returns it to the caller
   
   - parameter object: The object to copy
   
   - returns: The newly copied object
   */
  func copy<T: NSManagedObject>(object: T) -> T
  
  /**
   Copies the specified objects into the current thread's context and returns them to the caller
   
   - parameter objs: The objects to copy
   
   - returns: The newly copied objects
   */
  func copy<T: NSManagedObject>(objects objs: T...) -> [T]
  
  /**
   Copies the specified objects into the current thread's context and returns them to the caller
   
   - parameter objects: The objects to copy
   
   - returns: The newly copied objects
   */
  func copy<T: NSManagedObject>(objects: [T]) -> [T]
  
  /**
   Returns the number of results that would be returned if a fetch was performed using the specified query
   
   - parameter query: The query to perform
   
   - throws: An error will be thrown if the query cannot be performed
   
   - returns: The number of results
   */
  func count<T: NSManagedObject>(query: Query<T>) throws -> Int
  
  /**
   Performs a fetch using the specified query and returns the results to the caller
   
   - parameter query: The query to perform
   
   - throws: An eror will be thrown if the query cannot be performed
   
   - returns: The resulting objects or nil
   */
  func fetch<T: NSManagedObject>(query: Query<T>) throws -> [T]
  
  /**
   Performs a fetch using the specified query and returns the first result
   
   - parameter query: The query to perform
   
   - throws: An error will be thrown is the query cannot be performed
   
   - returns: The resulting object or nil
   */
  func fetch<T: NSManagedObject>(first query: Query<T>) throws -> T?
  
  /**
   Performs a fetch using the specified query and returns the last result
   
   - parameter query: The query to perform
   
   - throws: An error will be thrown is the query cannot be performed
   
   - returns: The resulting object or nil
   */
  func fetch<T: NSManagedObject>(last query: Query<T>) throws -> T?
  
  /**
   Performs a fetch using the specified NSManagedObjectID
   
   - parameter objectID: The objectID to use for this fetch
   
   - throws: An error will be thrown if the query cannot be performed
   
   - returns: The resulting object or nil
   */
  func fetch<T: NSManagedObject>(objectWithID objectID: NSManagedObjectID) throws -> T?
  
}

/**
 *  Provides a protocol for any class that supports Writing to a Stack
 */
public protocol Writable {
  
  /**
   Inserts a new entity of the specified class. Usage: `insert() as EntityName`
   */
  func insert<T: NSManagedObject>() throws -> T
  
  /**
   Fetches (or inserts if not found) an entity with the specified identifier
   */
  func fetchOrInsert<T: NSManagedObject, U: StackManagedKey>(key: String, identifier: U) throws -> T
  
  /**
   Fetches (or inserts if not found) entities with the specified identifiers
   */
  func fetchOrInsert<T: NSManagedObject, U: StackManagedKey>(key: String, identifiers: [U]) throws -> [T]

  /**
   Deletes the specified objects
   */
  func delete<T: NSManagedObject>(objects: T...) throws
  
  /**
   Deletes the specified objects
   */
  func delete<T: NSManagedObject>(objects objects: [T]) throws
  
}

// MARK: Error Handling

/**
Used throughout Stack to provide finer grained error handling

- EntityNameNotFoundForClass: The entity name you queried, couldn't be located for the specified class type
- EntityNotFoundInStack:      The entity could not be found in Stack. Generally indicates your class no longer maps to a valid entity in your model
- InvalidResultType:          The result type expected from a fetch request was invalid
- FetchError:                 A generic error occurred
*/
public enum StackError: ErrorType {
  case EntityNameNotFoundForClass(AnyClass)
  case EntityNotFoundInStack(Stack, String)
  case InvalidResultType(AnyClass.Type)
  case FetchError(NSError?)
}

// MARK: NSManagedObject Identifiers


/**
 *  Defines a protocol that all NSManagedObject key's must conform to in order to be used as an identifier
 */
public protocol StackManagedKey: NSObjectProtocol, Equatable, Hashable, CVarArgType { }
extension NSObject: StackManagedKey { } // adds support for all NSObject's to be used as a StackManagedKey

/**
*  Defines a protocol that all
*/
public protocol StackManagedObject { }
extension NSManagedObject: StackManagedObject { }


// MARK: Stack Support


/**
 *  Classes conforming to this protocol can provide access to a Stack
 */
public protocol StackSupport {
  
  /**
   Provides internal access to the stack.
   
   - returns: The stack associated with the receiver
   */
  func _stack() -> Stack
  
}

extension Readable where Self: Stack {

  /**
   Provides stack support for all classes conforming to Readable
   
   - returns: The stack associated with the reciever
   */
  public func _stack() -> Stack {
    return self
  }
  
}

extension Readable where Self: Transaction {
  
  /**
   Provides stack support for all classes conforming to Readable
   
   - returns: The stack associated with the reciever
   */
  public func _stack() -> Stack {
    return self.stack
  }
  
}

