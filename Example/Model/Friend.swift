//
//  Friend.swift
//  
//
//  Created by Shaps Mohsenin on 26/11/2015.
//
//

import Foundation
import CoreData
import Stack

@objc(Friend)
class Friend: NSManagedObject {

  override class func entityName() -> String {
    return "Friends"
  }
  
//  override class func primaryKey() -> (String, Any.Type) {
//    return ("name", String.self)
//  }

}
