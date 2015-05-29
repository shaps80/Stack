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
  
  Stack *stack = [Stack memoryStack];
  StackQuery *query = stack.query(Person.class);
  
  [self deleteObjectsWithQuery:query];
}

- (void)deleteObjectsWithQuery:(StackQuery *)query
{
  query.delete();
  NSLog(@"%zd", query.count());
}

- (void)createObjectsWithQuery:(StackQuery *)query stack:(Stack *)stack
{
  StackQuery *q = Stack.defaultStack.query(Person.class);
  NSArray *people = q.fetch();
  
  for (int i = 0; i < 100; i++) {
    stack.transaction(^{
      @stack_copy(people);
      
      [people firstObject];
      stack.query(Person.class).whereIdentifiers(@[ @"", @"", @"" ], YES);
      
      NSString *identifier = [NSString stringWithFormat:@"id-%zd", i];
      Person *person = stack.query(Person.class).whereIdentifier(identifier, YES);
      person.name = @"Shaps";
      
    });
  }
  
  NSLog(@"%zd", query.count());
}

- (void)updateObject:(Person *)person withStack:(Stack *)stack
{
  NSLog(@"Before: %@", person.name);
  
  stack.transaction(^{
    @stack_copy(person);
    person.name = @"Mohsenin";
  });
  
  NSLog(@"After: %@", [stack.query(person.class).fetch().firstObject name]);
}

@end

