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

/**
 *  Provides a protocol for any class that supports Reading from a Stack
 */
public protocol Readable: StackSupport {
  
  /**
   Copies the specified object into the current thread's context and returns it to the caller
   */
  func copy<T: NSManagedObject>(object: T) -> T
  
  /**
   Copies the specified objects into the current thread's context and returns them to the caller
   */
  func copy<T: NSManagedObject>(objects objs: T...) -> [T]
  
  /**
   Copies the specified objects into the current thread's context and returns them to the caller
   */
  func copy<T: NSManagedObject>(objects: [T]) -> [T]
  
  /**
   Returns the number of results that would be returned if a fetch was performed using the specified query
   */
  func count<T: NSManagedObject>(query: Query<T>) throws -> Int
  
  /**
   Performs a fetch using the specified query and returns the results to the caller
   */
  func fetch<T: NSManagedObject>(query: Query<T>) throws -> [T]
  
  /**
   Performs a fetch using the specified query and returns the first result
   */
  func fetch<T: NSManagedObject>(first query: Query<T>) throws -> T?
  
  /**
   Performs a fetch using the specified query and returns the last result
   */
  func fetch<T: NSManagedObject>(last query: Query<T>) throws -> T?
  
  /**
   Performs a fetch, querying CoreData for an entity with the specified identifier
   */
  func fetch<T: NSManagedObject, U: StackManagedKey>(key: String, identifier: U) throws -> T?
  
  /**
   Performs a fetch, querying CoreData for an entity with the specified identifiers
   */
  func fetch<T: NSManagedObject, U: StackManagedKey>(key: String, identifiers: [U]) throws -> [T]?
  
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
   Performs a fetch using the specified NSManagedObjectID
   */
  func fetch<T: NSManagedObject>(objectWithID objectID: NSManagedObjectID) throws -> T?

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
extension NSObject: StackManagedKey { }

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
   */
  func _stack() -> Stack
  
}

extension Readable where Self: Stack {

  /**
   Provides stack support for all classes conforming to Readable
   */
  public func _stack() -> Stack {
    return self
  }
  
}

extension Readable where Self: Transaction {
  
  /**
   Provides stack support for all classes conforming to Readable
   */
  public func _stack() -> Stack {
    return self.stack
  }
  
}

