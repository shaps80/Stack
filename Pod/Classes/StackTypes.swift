//
//  StackTypes.swift
//  Stack
//
//  Created by Shaps Mohsenin on 19/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import CoreData

public enum StackError: ErrorType {
  case EntityNameNotFoundForClass(AnyClass)
  case EntityNotFoundInStack(Stack, String)
  case InvalidResultType(AnyClass.Type)
  case FetchError(NSError?)
  case SaveFailed(NSError?)
  case DeleteFailed(String)
}

public enum QueryResultType {
  case ManagedObjects
  case ManagedObjectIDs
  case Dictionaries
  
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

public protocol StackManagedKey: NSObjectProtocol, Equatable, Hashable, CVarArgType { }
extension NSObject: StackManagedKey { }

public protocol Writable {
  
  func copy<T: NSManagedObject>(object: T) -> T
  func copy<T: NSManagedObject>(objects objs: T...) -> [T]
  func copy<T: NSManagedObject>(objects: [T]) -> [T]
  
  func insert<T: NSManagedObject>() throws -> T
  func insertOrFetch<T: NSManagedObject, U: StackManagedKey>(key: String, identifier: U) throws -> T
  func insertOrFetch<T: NSManagedObject, U: StackManagedKey>(key: String, identifiers: [U]) throws -> [T]

  func delete<T: NSManagedObject>(objects: T...) throws
  func delete<T: NSManagedObject>(objects objects: [T]) throws
  
}

public protocol Readable: StackSupport {
  
  func count<T: NSManagedObject>(query: Query<T>) throws -> Int
  
  func fetch<T: NSManagedObject>(query: Query<T>) throws -> [T]
  func fetch<T: NSManagedObject>(first query: Query<T>) throws -> T?
  func fetch<T: NSManagedObject>(last query: Query<T>) throws -> T?
  
}

extension Readable where Self: Stack {
  
  public func _stack() -> Stack {
    return self
  }
  
}

extension Readable where Self: Transaction {
  
  public func _stack() -> Stack {
    return self.stack
  }
  
}

extension Readable {
  
  public func count<T: NSManagedObject>(query: Query<T>) throws -> Int {
    let request = try fetchRequest(query)
    var error: NSError?
    let count = _stack().currentThreadContext().countForFetchRequest(request, error: &error)
    
    if let error = error {
      throw StackError.FetchError(error)
    }
    
    return count
  }
  
  public func fetch<T: NSManagedObject>(query: Query<T>) throws -> [T] {
    let request = try fetchRequest(query)

    let stack = _stack()
    let context = stack.currentThreadContext()

    guard let results = try context.executeFetchRequest(request) as? [T] else {
      throw StackError.InvalidResultType(T.Type)
    }
    
    return results
  }
  
  public func fetch<T: NSManagedObject>(first query: Query<T>) throws -> T? {
    return try fetch(query).first
  }
  
  public func fetch<T: NSManagedObject>(last query: Query<T>) throws -> T? {
    return try fetch(query).first
  }
  
  func fetchRequest<T: NSManagedObject>(query: Query<T>) throws -> NSFetchRequest {
    guard let entityName = _stack().entityNameForManagedObjectClass(T) else {
      throw StackError.EntityNameNotFoundForClass(T)
    }
    
    guard let request = query.fetchRequestForEntityNamed(entityName) else {
      throw StackError.EntityNotFoundInStack(_stack(), entityName)
    }

    return request
  }
  
}

public protocol StackSupport {
  
  func _stack() -> Stack
  
}
