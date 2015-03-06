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
  
  Stack *stack = [Stack defaultStack];
  StackQuery *query = stack.query(Person.class);
  
  query.delete();
  
  NSUInteger count = query.count();
  NSLog(@"%zd", count);
  
  
//  for (int i = 0; i < 100; i++) {
//
//    stack.transaction(^{
//      
//      NSString *identifier = [NSString stringWithFormat:@"id-%zd", i];
//      Person *person = stack.query(Person.class).whereIdentifier(identifier, YES);
//      person.name = @"Shaps";
//      
//    }).synchronous(YES);
//  }
}

@end

