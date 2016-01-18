//
//  ViewController.swift
//  Stack
//
//  Created by Shaps Mohsenin on 11/26/2015.
//  Copyright (c) 2015 Shaps Mohsenin. All rights reserved.
//

import UIKit
import Stack
import CoreData

class ViewController: UITableViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let stack = Stack.defaultStack()
    let query = Query<Friend>().fault(true).sort(byKey: "name", ascending: true)
    
    let person = stack.fetch(query).first
    print(person)
    
    stack.write { (transaction) -> Void in
      let person = try! transaction.insertOrFetch("name", identifier: "shaps") as Person
      print(person.name)
    }
  }
  
}

