//
//  StackViewController.m
//  Stack
//
//  Created by Shaps Mohsenin on 02/08/2015.
//  Copyright (c) 2014 Shaps Mohsenin. All rights reserved.
//

#import "StackViewController.h"
#import "Stack.h"
#import "Person.h"

@interface StackViewController ()
@end

@implementation StackViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  NSDictionary *attributes = nil;
  
  for (int i = 0; i < 1000; i++) {
    Stack.defaultStack.syncTransaction(^{
      
      for (int j = 0; j < 1000; j++) {
        NSString *identifier = [NSString stringWithFormat:@"10%zd%dz", i, j];
        Person *person = Person.query.whereIdentifier(identifier, YES);
        
        person.update(@
        {
          @"name" : attributes[@"name"],
          @"phone" : attributes[@"phone_number"],
        });
        
        Person.query.sortByKey(@"name", YES).delete();
        NSArray *people = Person.query.sortByKey(@"name", YES).fetch();
        
        NSLog(@"%@", people);
      }
      
    });
  }
  
//  NSArray *people = Person.query.where(@"name == shaps").fetch();
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    
//    Stack.defaultStack.transaction
    
  });
}

@end

