//
//  NSFetchedResultsController+Stack.swift
//  Stack
//
//  Created by Shaps Mohsenin on 26/11/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import CoreData

extension NSFetchedResultsController {
  
  public convenience init<T>(stack: Stack, query: Query<T>) {
    self.init()
  }
  
}
