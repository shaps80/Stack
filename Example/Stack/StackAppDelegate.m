//
//  StackAppDelegate.m
//  Stack
//
//  Created by CocoaPods on 02/08/2015.
//  Copyright (c) 2014 Shaps Mohsenin. All rights reserved.
//

#import "StackAppDelegate.h"
//#import "Stack-Swift.h"

@implementation StackAppDelegate

- (BOOL)application:(nonnull UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
  
  
  /*
   let stack = Stack.defaultStack()
   let query = Query<Person>().sort("name", ascending: true).filter(predicate: NSPredicate(value: true))
   
   let person = stack.fetch(query).first!
   
   stack.write { (transaction: Transaction) -> Void in
   
   // perhaps we could add a check in the implementation right before a save:
   // we check the object.managedObjectContext is equal to the transaction.managedObjectContext
   
   let p = transaction.copy(person)
   p.name = "Anne"
   
   print(person)
   }
   
   print(person)
   */
  
  return YES;
}

@end
