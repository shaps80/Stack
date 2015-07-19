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


@implementation StackViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  Stack *stack = [Stack memoryStack];
  StackQuery *query = stack.query(Person.class);
  
  [self createObjectsWithQuery:query];
//  [self deleteObjectsWithQuery:query];
}

- (void)deleteObjectsWithQuery:(StackQuery *)query
{
  query.delete();
  NSLog(@"%zd", query.count());
}

- (void)createObjectsWithQuery:(StackQuery *)query
{
  NSArray *people = query.fetch();
  Person *person = query.whereIdentifier(@"124").fetchOrCreate();
  
  stack_prepare(people, person);
  for (int i = 0; i < 100; i++) {
    query.stack.transaction(^{
      stack_copy(people, person);
      person.name = @"Shaps";
    });
  }
  
  NSLog(@"%zd", query.count());
}

- (void)updateObject:(Person *)person withStack:(Stack *)stack
{
  NSLog(@"Before: %@", person.name);
  
//  stack_prepare(person);
  stack.transaction(^{
//    stack_copy(person);
    person.name = @"Mohsenin";
  });
  
  NSLog(@"After: %@", [stack.query(person.class).fetch() name]);
}

@end

