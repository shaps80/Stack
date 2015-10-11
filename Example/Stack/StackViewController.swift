
//  StackViewController.swift
//  Stack
//
//  Created by Shaps Mohsenin on 14/08/2015.
//  Copyright © 2015 Shaps Mohsenin. All rights reserved.
//

import UIKit

class StackViewController: UITableViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let stack = Stack.defaultStack()
    let query = Query<Person>().sort("name", ascending: true)
    
    let person = stack.fetch(firstInQuery: query)
    
    stack.write { (transaction) -> Void in
//      let address = transaction.insert()
//      let address = transaction.insert()
      
      let people = transaction.copy(person!)
      print(people.name)
    }
    
//    let person = stack.fetch(query)
//    let person = stack.fetch(firstInQuery: query)
//    let p: Person = stack.fetch(query)
    
//    print(p.name)
    
//    print(person)
    
//    stack.write { (transaction) -> Void in
//      let person: Person = transaction.insert()
    

//      try! transaction.context.save()
//      print(person)
    }
  
}

